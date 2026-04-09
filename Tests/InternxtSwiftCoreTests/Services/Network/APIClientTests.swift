//
//  File.swift
//  InternxtSwiftCore
//
//  Created by Patricio Tovar on 30/6/25.
//

import Foundation
import XCTest
@testable import InternxtSwiftCore

final class APIClientTests: XCTestCase {
    
    struct DummyResponse: Decodable {
        let message: String
        let statusCode: Int
    }
    
    var client: APIClient!
    var mockSession: URLSession!
   
    override func setUp() {
        super.setUp()
        setupMockClient()
    }
    
    override func tearDown() {
        client = nil
        mockSession = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func setupMockClient(config: RateLimitConfiguration? = nil) {
        let urlConfig = URLSessionConfiguration.ephemeral
        urlConfig.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: urlConfig)
        
        let rateLimitConfig = config ?? RateLimitConfiguration(
            maxRetries: 2,
            baseDelay: 0.1,
            maxDelay: 1.0,
            backoffMultiplier: 2.0
        )
        
        client = APIClient(urlSession: mockSession, rateLimitConfiguration: rateLimitConfig)
    }
    
    private func createMockResponse(statusCode: Int, headers: [String: String]? = nil, body: String? = nil) -> (HTTPURLResponse, Data?) {
        let url = URL(string: "https://mock.test")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: headers
        )!
        let data = body?.data(using: .utf8)
        return (response, data)
    }
    
    private func createSuccessResponse() -> (HTTPURLResponse, Data?) {
        return createMockResponse(
            statusCode: 200,
            body: "{\"message\": \"OK\", \"statusCode\": 200}"
        )
    }
    
    private func createErrorResponse(statusCode: Int, message: String = "Server Error") -> (HTTPURLResponse, Data?) {
        return createMockResponse(
            statusCode: statusCode,
            body: "{\"message\": \"\(message)\"}"
        )
    }

    func test429WithRetryAfterHeader() async throws {
        var callCount = 0
        
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            if callCount == 1 {
                let headers = ["Retry-After": "1"]
                let response = HTTPURLResponse(url: request.url!, statusCode: 429, httpVersion: nil, headerFields: headers)!
                return (response, "{\"message\": \"Rate limited\"}".data(using: .utf8))
            } else {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, "{\"message\": \"OK\", \"statusCode\": 200}".data(using: .utf8))
            }
        }


        let endpoint = Endpoint(path: "https://mock.test", method: .GET)

        let start = Date()
        let result: DummyResponse = try await client.fetch(type: DummyResponse.self, endpoint)
        let duration = Date().timeIntervalSince(start)

        XCTAssertEqual(result.message, "OK")
        XCTAssertTrue(duration >= 1.0, "Should wait 1s due to Retry-After")
    }

    func testServerErrorRetriesAndSucceeds() async throws {
        var callCount = 0

        MockURLProtocol.requestHandler = { request in
            callCount += 1
            if callCount < 3 {
                let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
                return (response, "{\"message\": \"Internal Server Error\"}".data(using: .utf8))
            } else {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, "{\"message\": \"OK\", \"statusCode\": 200}".data(using: .utf8))
            }
        }

        struct DummyResponse: Decodable {
            let message: String
            let statusCode: Int
        }

        let endpoint = Endpoint(path: "https://mock.test", method: .GET)
        let result: DummyResponse = try await client.fetch(type: DummyResponse.self, endpoint)

        XCTAssertEqual(result.message, "OK")
        XCTAssertEqual(callCount, 3, "Should retry 2 times then succeed")
    }

    func testMaxRetriesExceeded() async {
        var callCount = 0

        MockURLProtocol.requestHandler = { request in
            callCount += 1
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, "{\"message\": \"Server Error\"}".data(using: .utf8))
        }

        struct DummyResponse: Decodable {
            let message: String
        }

        let endpoint = Endpoint(path: "https://mock.test", method: .GET)

        do {
            _ = try await client.fetch(type: DummyResponse.self, endpoint)
            XCTFail("Expected to throw after max retries")
        } catch let err as APIClientError {
            XCTAssertEqual(err.statusCode, 500)
            XCTAssertEqual(callCount, 3, "Initial + 2 retries")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    

    
    
    // MARK: - Adaptive Delay Tests
    
    func testAdaptiveDelayIncreasesWithConsecutiveFailures() async {
        let config = RateLimitConfiguration(
            baseDelay: 1.0,
            maxDelay: 60.0,
            backoffMultiplier: 2.0
        )
        setupMockClient(config: config)

        // Simulate consecutive server throttling
        await client.rateLimitState.markServerThrottled(duration: 1.0)
        await client.rateLimitState.markServerThrottled(duration: 1.0)
        await client.rateLimitState.markServerThrottled(duration: 1.0)

        let delay = await client.calculateAdaptiveDelay(attempt: 1)

        // baseDelay * 2^1 = 2.0
        // adaptiveMultiplier = 1.0 + (3 * 0.5) = 2.5
        // expected = 2.0 * 2.5 = 5.0
        XCTAssertEqual(delay, 5.0, accuracy: 0.1,
                      "Adaptive delay should increase with consecutive failures")
        
    }
    
    func testAdaptiveDelayRespectsMaxDelay() async {
        let config = RateLimitConfiguration(
            baseDelay: 10.0,
            maxDelay: 15.0,
            backoffMultiplier: 3.0
        )
        setupMockClient(config: config)

        // Create many consecutive failures
        for _ in 0..<10 {
            await client.rateLimitState.markServerThrottled(duration: 1.0)
        }

        let delay = await client.calculateAdaptiveDelay(attempt: 5)

        XCTAssertLessThanOrEqual(delay, config.maxDelay,
                                "Adaptive delay should not exceed maxDelay")
    }
    
    func testCancellationCancelsDataTask() async {
        let endpoint = Endpoint(path: "https://mock.test", method: .GET)
        let requestStarted = expectation(description: "Request started")
        
        MockURLProtocol.requestHandler = { _ in
            requestStarted.fulfill()
            try await Task.sleep(nanoseconds: 10_000_000_000)
            return self.createSuccessResponse()
        }

        let task = Task {
            try await client.fetch(type: DummyResponse.self, endpoint)
        }
        
        await fulfillment(of: [requestStarted], timeout: 1.0)
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Task should have been cancelled and thrown CancellationError")
        } catch is CancellationError {
        } catch {
            XCTFail("Expected CancellationError, got \(type(of: error)): \(error)")
        }
    }
    
    // MARK: - Token Bucket Rate Limiting Tests
    
    func testTokenBucketEnforcesRateLimit() async throws {
        let restrictiveConfig = RateLimitConfiguration(
            maxConcurrentRequests: 10,
            requestsPerSecond: 2.0,
            burstCapacity: 3,
            maxRetries: 0,
            baseDelay: 0.1
        )
        setupMockClient(config: restrictiveConfig)
        
        var requestTimes: [Date] = []
        let requestTimesLock = NSLock()
        
        MockURLProtocol.requestHandler = { request in
            requestTimesLock.lock()
            requestTimes.append(Date())
            requestTimesLock.unlock()
            
            return self.createSuccessResponse()
        }

        let endpoint = Endpoint(path: "https://mock.test", method: .GET)
        let startTime = Date()
    
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    do {
                        _ = try await self.client.fetch(type: DummyResponse.self, endpoint)
                    } catch {
                     
                    }
                }
            }
        }
        
        let totalDuration = Date().timeIntervalSince(startTime)
        
        requestTimesLock.lock()
        let finalRequestTimes = requestTimes
        requestTimesLock.unlock()
        
        XCTAssertEqual(finalRequestTimes.count, 5, "All 5 requests should complete")
        
        // With 2 requests/second and 5 total requests:
        // - First 3 requests can use burst capacity (immediate)
        // - Remaining 2 requests need to wait 0.5s each
        // - Total minimum time should be ~1.0s
        XCTAssertGreaterThanOrEqual(totalDuration, 1.0,
                                   "Token bucket should enforce rate limiting")
        
        if finalRequestTimes.count >= 4 {
            let sortedTimes = finalRequestTimes.sorted()
            let timeBetween3rdAnd4th = sortedTimes[3].timeIntervalSince(sortedTimes[2])
            XCTAssertGreaterThanOrEqual(timeBetween3rdAnd4th, 0.4,
                                       "Should enforce ~0.5s spacing between rate-limited requests")
        }
    }
    
    // MARK: - Concurrency Limiting Tests
    
    func testConcurrencyLimitingPreventsExcessiveParallelRequests() async throws {
        let concurrencyConfig = RateLimitConfiguration(
            maxConcurrentRequests: 2,
            requestsPerSecond: 100.0,
            burstCapacity: 100,
            maxRetries: 0
        )
        setupMockClient(config: concurrencyConfig)
        
        let concurrencyTracker = ConcurrencyTracker()
        
        MockURLProtocol.requestHandler = { request in
            await concurrencyTracker.requestStarted()
           
            try await Task.sleep(nanoseconds: 200_000_000)
            
            await concurrencyTracker.requestCompleted()
            return self.createSuccessResponse()
        }

        let endpoint = Endpoint(path: "https://mock.test", method: .GET)
        
        // Launch more requests than the concurrency limit
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    do {
                        _ = try await self.client.fetch(type: DummyResponse.self, endpoint)
                    } catch {
                      
                    }
                }
            }
        }
        
        let maxConcurrent = await concurrencyTracker.getMaxConcurrentCount()
        
        XCTAssertLessThanOrEqual(maxConcurrent, 2,
                                "Should never exceed concurrency limit of 2")
        XCTAssertGreaterThan(maxConcurrent, 0,
                            "Should have processed at least some concurrent requests")
    }

    // MARK: - Queue Overflow Tests
    
    func testSemaphoreQueueOverflowHandling() async {
        let overflowConfig = RateLimitConfiguration(
            maxConcurrentRequests: 1,
            requestsPerSecond: 0.1,
            burstCapacity: 1,
            maxRetries: 0
        )
        setupMockClient(config: overflowConfig)
        
        MockURLProtocol.requestHandler = { request in
            // Make requests take a very long time to force queue overflow
            try await Task.sleep(nanoseconds: 5_000_000_000)
            return self.createSuccessResponse()
        }

        let endpoint = Endpoint(path: "https://mock.test", method: .GET)
        let errorCounter = ErrorCounter()
        
        // Launch many more requests than can be queued
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<60 {
                group.addTask {
                    do {
                        _ = try await self.client.fetch(type: DummyResponse.self, endpoint)
                    } catch let error as APIClientError {
                        if error.statusCode == -2 && error.localizedDescription.contains("Request queue full") {
                            await errorCounter.increment()
                        }
                    } catch {
                    }
                }
            }
        }
        
        let queueFullErrors = await errorCounter.getCount()
        
        XCTAssertGreaterThan(queueFullErrors, 0,
                            "Should generate queue overflow errors when too many requests are queued")
    }
    
    // MARK: - Error Handling Tests
    
    func test4xxErrorsAreNotRetried() async {
        var requestCount = 0
        
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            return self.createErrorResponse(statusCode: 404, message: "Not Found")
        }

        let endpoint = Endpoint(path: "https://mock.test", method: .GET)

        do {
            _ = try await client.fetch(type: DummyResponse.self, endpoint)
            XCTFail("Expected APIClientError for 404 status")
        } catch let error as APIClientError {
            XCTAssertEqual(error.statusCode, 404)
            XCTAssertEqual(requestCount, 1, "4xx errors should not be retried")
        } catch {
            XCTFail("Expected APIClientError, got: \(type(of: error))")
        }
    }
}

// MARK: - Helper Classes

actor ConcurrencyTracker {
    private var currentCount = 0
    private var maxCount = 0
    
    func requestStarted() {
        currentCount += 1
        maxCount = max(maxCount, currentCount)
    }
    
    func requestCompleted() {
        currentCount -= 1
    }
    
    func getMaxConcurrentCount() -> Int {
        return maxCount
    }
}

actor ErrorCounter {
    private var count = 0
    
    func increment() {
        count += 1
    }
    
    func getCount() -> Int {
        return count
    }
}
