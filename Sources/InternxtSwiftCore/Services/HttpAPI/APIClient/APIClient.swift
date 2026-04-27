//
//  ApiClient.swift
//  
//
//  Created by Robert Garcia on 1/8/23.
//

import Foundation
import Combine

public struct APIClientError: Error {
    public var statusCode: Int
    public var responseBody: Data
    public var headers: [String: String]
    public var message: String

    public var localizedDescription: String {
        return self.message
    }
    
    public init(statusCode: Int, message: String, responseBody: Data = Data(), headers: [String: String] = [:]) {
        self.statusCode = statusCode
        self.message = message
        self.responseBody = responseBody
        self.headers = headers
    }
}

public struct RateLimitConfiguration {
    let maxConcurrentRequests: Int
    let requestsPerSecond: Double
    let burstCapacity: Int
    let maxRetries: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let backoffMultiplier: Double
    
    public init(maxConcurrentRequests: Int = 8,
                requestsPerSecond: Double = 8.0,
                burstCapacity: Int = 20,
                maxRetries: Int = 3,
                baseDelay: TimeInterval = 1.0,
                maxDelay: TimeInterval = 120.0,
                backoffMultiplier: Double = 2.0) {
        self.maxConcurrentRequests = maxConcurrentRequests
        self.requestsPerSecond = requestsPerSecond
        self.burstCapacity = burstCapacity
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.backoffMultiplier = backoffMultiplier
    }
}

actor TokenBucket {
    private var tokens: Double
    private let capacity: Double
    private let refillRate: Double
    private var lastRefill: Date
    private let maxTrackingInterval: TimeInterval = 300
   
    init(capacity: Double, refillRate: Double) {
        self.capacity = capacity
        self.refillRate = refillRate
        self.tokens = capacity
        self.lastRefill = Date()
    }
    
    func consume() async -> Bool {
        refillTokens()
        
        if tokens >= 1.0 {
            tokens -= 1.0
            return true
        }
        return false
    }
    
    private func refillTokens() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastRefill)
        
        let cappedElapsed = min(elapsed, maxTrackingInterval)
        let tokensToAdd = cappedElapsed * refillRate
        
        tokens = min(capacity, tokens + tokensToAdd)
        lastRefill = now
    }
        
    func waitTimeForNextToken() async -> TimeInterval {
        refillTokens()
        if tokens >= 1.0 {
            return 0
        }
        return min((1.0 - tokens) / refillRate, maxTrackingInterval)
    }
}

actor RateLimitState {
    private var isServerThrottled: Bool = false
    private var throttleEndTime: Date?
    private var consecutiveFailures: Int = 0
    private var lastFailureTime: Date?
    
    func markServerThrottled(duration: TimeInterval) {
        isServerThrottled = true
        throttleEndTime = Date().addingTimeInterval(duration)
        consecutiveFailures += 1
        lastFailureTime = Date()
    }
    
    func markSuccessfulRequest() {
        if consecutiveFailures > 0 {
            consecutiveFailures = max(0, consecutiveFailures - 1)
        }
        
        if consecutiveFailures == 0 {
            isServerThrottled = false
            throttleEndTime = nil
        }
    }
    
    func shouldThrottle() -> (shouldWait: Bool, waitTime: TimeInterval) {
        let now = Date()
        
        if let throttleEnd = throttleEndTime, now < throttleEnd {
            return (true, throttleEnd.timeIntervalSince(now))
        }
        
        if consecutiveFailures > 0, let lastFailure = lastFailureTime {
            let timeSinceLastFailure = now.timeIntervalSince(lastFailure)
            let expectedWaitTime = Double(consecutiveFailures) * 2.0
            
            if timeSinceLastFailure < expectedWaitTime {
                return (true, expectedWaitTime - timeSinceLastFailure)
            }
        }
        
        return (false, 0)
    }
    
    func getConsecutiveFailures() -> Int {
        return consecutiveFailures
    }
}

actor BoundedAsyncSemaphore {
    private var count: Int
    private var waiters: [WaiterInfo] = []
    private let maxWaiters: Int
    
    private struct WaiterInfo {
        let id: UUID
        let continuation: CheckedContinuation<Void, Error>
    }
    
    init(value: Int, maxWaiters: Int = 100) {
        self.count = value
        self.maxWaiters = maxWaiters
    }
    
    func wait() async throws {
        if count > 0 {
            count -= 1
            return
        }
        
        guard waiters.count < maxWaiters else {
            throw APIClientError(statusCode: -2, message: "Request queue full")
        }
        
        let waiterID = UUID()
        
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let waiterInfo = WaiterInfo(id: waiterID, continuation: continuation)
                waiters.append(waiterInfo)
            }
        } onCancel: {
            Task {
                await self.removeCancelledWaiter(id: waiterID)
            }
        }
    }
    
    private func removeCancelledWaiter(id: UUID) {
        if let index = waiters.firstIndex(where: { $0.id == id }) {
            let cancelledWaiter = waiters.remove(at: index)
            cancelledWaiter.continuation.resume(throwing: CancellationError())
        }
    }
    
    func signal() {
        if waiters.isEmpty {
            count += 1
        } else {
            let waiter = waiters.removeFirst()
            waiter.continuation.resume()
        }
    }
}

private class DateFormatterCache {
    static let shared = DateFormatterCache()
    
    private let formatters: [DateFormatter] = {
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss zzz",
            "EEEE, dd-MMM-yy HH:mm:ss zzz",
            "EEE MMM dd HH:mm:ss yyyy"
        ]
        
        return formats.map { format in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(abbreviation: "GMT")
            return formatter
        }
    }()
    
    func parseHTTPDate(_ dateString: String) -> Date? {
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }
}

@available(macOS 10.15, *)
public struct APIClient {
    /// Shared ephemeral URLSession that avoids DNS and HTTP caching.
    public static let ephemeralSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.httpCookieStorage = nil
        return URLSession(configuration: config)
    }()
    
    public static var onUnauthorized: (() -> Void)? = nil
    
    var urlSession: URLSession
    var authorizationHeaderValue: String? = nil
    var clientName: String? = nil
    var clientVersion: String? = nil
    var workspaceHeader: String? = nil
    var authorizationHeaderGatewayValue: String? = nil
    
    var rateLimitConfiguration: RateLimitConfiguration
        
    private let tokenBucket: TokenBucket
    internal let rateLimitState: RateLimitState
    private let semaphore: BoundedAsyncSemaphore
    
    init(
        urlSession: URLSession = APIClient.ephemeralSession,
        authorizationHeaderValue: String? = nil,
        clientName: String? = nil,
        clientVersion: String? = nil,
        workspaceHeader: String? = nil,
        authorizationHeaderGatewayValue: String? = nil,
        rateLimitConfiguration: RateLimitConfiguration = RateLimitConfiguration()
    ) {
        self.urlSession = urlSession
        self.authorizationHeaderValue = authorizationHeaderValue
        self.clientName = clientName
        self.clientVersion = clientVersion
        self.workspaceHeader = workspaceHeader
        self.authorizationHeaderGatewayValue = authorizationHeaderGatewayValue
        self.rateLimitConfiguration = rateLimitConfiguration
        self.tokenBucket = TokenBucket(
            capacity: Double(rateLimitConfiguration.burstCapacity),
            refillRate: rateLimitConfiguration.requestsPerSecond
        )
        self.rateLimitState = RateLimitState()
        self.semaphore = BoundedAsyncSemaphore(
            value: rateLimitConfiguration.maxConcurrentRequests,
            maxWaiters: 50
        )
    }
    
    func fetch<T: Decodable>(type: T.Type?, _ endpoint: Endpoint, debugResponse: Bool? = nil) async throws -> T {
        return try await fetchWithRateLimit(type: type, endpoint, debugResponse: debugResponse)
    }
    
    private func fetchWithRateLimit<T: Decodable>(type: T.Type?, _ endpoint: Endpoint, debugResponse: Bool?) async throws -> T {
        try await semaphore.wait()
        
        defer {
            Task {
                await semaphore.signal()
            }
        }
        
        let (shouldWait, waitTime) = await rateLimitState.shouldThrottle()
        if shouldWait {
            if debugResponse == true {
                print("Waiting \(waitTime)s due to server throttling")
            }
            try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        
        // Token bucket rate limiting
        while !(await tokenBucket.consume()) {
            let waitTime = await tokenBucket.waitTimeForNextToken()
            if debugResponse == true {
                print("Rate limiting locally - waiting \(waitTime)s")
            }
            try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        
        return try await fetchWithRetry(type: type, endpoint, debugResponse: debugResponse, attempt: 0)
    }
    
    // MARK: - Helper Methods
    
    private func shouldRetry(attempt: Int) -> Bool {
        return attempt < rateLimitConfiguration.maxRetries
    }
    
    private func calculateDelay(attempt: Int) -> TimeInterval {
        let exponentialDelay = rateLimitConfiguration.baseDelay * pow(rateLimitConfiguration.backoffMultiplier, Double(attempt))
        let jitter = Double.random(in: 0...0.1) * exponentialDelay
        return min(exponentialDelay + jitter, rateLimitConfiguration.maxDelay)
    }
    
    internal func calculateAdaptiveDelay(attempt: Int) async -> TimeInterval {
        let failures = await rateLimitState.getConsecutiveFailures()
        let baseDelay = rateLimitConfiguration.baseDelay * pow(rateLimitConfiguration.backoffMultiplier, Double(attempt))
        let adaptiveMultiplier = 1.0 + (Double(failures) * 0.5)
        
        return min(baseDelay * adaptiveMultiplier, rateLimitConfiguration.maxDelay)
    }
    
  
    private func safeEndpointDescription(_ endpoint: Endpoint) -> String {
        let method = endpoint.method.rawValue
        guard let url = URL(string: endpoint.path) else {
            return "[\(method) unknown]"
        }
        return "[\(method) \(url.path)]"
    }
    
    private func buildURLRequest(endpoint: Endpoint) throws -> URLRequest {
        guard let url = URL(string: endpoint.path) else {
            throw APIClientError(statusCode: -1, message: "Unable to build URL from \(endpoint.path)")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method.rawValue.lowercased()
        
        if let authorizationHeaderValue = self.authorizationHeaderValue {
            urlRequest.setValue(authorizationHeaderValue, forHTTPHeaderField: "Authorization")
        }

        if let workspaceHeaderValue = self.workspaceHeader {
            urlRequest.setValue(workspaceHeaderValue, forHTTPHeaderField: "x-internxt-workspace")
        }

        if let authorizationHeaderGatewayValue = self.authorizationHeaderGatewayValue {
            urlRequest.setValue(authorizationHeaderGatewayValue, forHTTPHeaderField: "x-internxt-desktop-header")
        }

        urlRequest.setValue(clientName, forHTTPHeaderField: "internxt-client")
        urlRequest.setValue(clientVersion, forHTTPHeaderField: "internxt-version")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = endpoint.body {
            urlRequest.httpBody = body
        }

        return urlRequest
    }
    
    private func extractRetryAfter(from error: APIClientError) -> TimeInterval? {
        let retryAfterValue = error.headers.first { key, _ in
            key.lowercased() == "retry-after"
        }?.value
        
        guard let retryAfterString = retryAfterValue else {
            return nil
        }
        
        if let seconds = TimeInterval(retryAfterString) {
            return min(max(seconds, 1), 3600)
        }
        
        if let date = DateFormatterCache.shared.parseHTTPDate(retryAfterString) {
            let timeInterval = date.timeIntervalSinceNow
            if timeInterval > 0 && timeInterval <= 3600 {
                return timeInterval
            }
        }
        
        return nil
    }
}

struct APIErrorResponse: Decodable {
    let message: String
    let error: String?
    let statusCode: Int
}

// MARK: - Request Execution
extension APIClient {
    
    private actor URLSessionTaskActor {
        weak var task: URLSessionTask?

        func setTask(_ task: URLSessionTask) {
            self.task = task
        }

        func cancel() {
            task?.cancel()
        }
    }
    
    private func performRequest<T: Decodable>(type: T.Type?, _ endpoint: Endpoint, debugResponse: Bool?) async throws -> T {
        let request: URLRequest = try buildURLRequest(endpoint: endpoint)
        
        let taskActor = URLSessionTaskActor()
        
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let task = urlSession.dataTask(with: request) { (data, response, error) in
                 
                    if Task.isCancelled {
                        continuation.resume(with: .failure(CancellationError()))
                        return
                    }
                    
                    if let error = error {
                        if let urlError = error as? URLError, urlError.code == .cancelled {
                            continuation.resume(with: .failure(CancellationError()))
                            return
                        }
                        let endpointDesc = self.safeEndpointDescription(endpoint)
                        if debugResponse == true {
                            print("API CLIENT ERROR \(endpointDesc)", error)
                        }
                        continuation.resume(with: .failure(APIClientError(statusCode: -1, message: "\(endpointDesc) \(error.localizedDescription)")))
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        let endpointDesc = self.safeEndpointDescription(endpoint)
                        continuation.resume(with: .failure(APIClientError(statusCode: -1, message: "\(endpointDesc) No HTTP response")))
                        return
                    }
                    
                    let headers = httpResponse.allHeaderFields.reduce(into: [String: String]()) { result, header in
                        if let key = header.key as? String, let value = header.value as? String {
                            result[key] = value
                        }
                    }
                    
                    do {
                        guard let data = data else {
                            let endpointDesc = self.safeEndpointDescription(endpoint)
                            throw APIClientError(
                                statusCode: httpResponse.statusCode,
                                message: "\(endpointDesc) Response is empty",
                                headers: headers
                            )
                        }
                        
                        if !(200...399).contains(httpResponse.statusCode) {
                            let endpointDesc = self.safeEndpointDescription(endpoint)
                            let errorMessage: String
                            
                            if let decodedError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                                errorMessage = "\(endpointDesc) \(decodedError.message)"
                            } else {
                                errorMessage = "\(endpointDesc) \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))"
                            }
                            
                            let apiError = APIClientError(
                                statusCode: httpResponse.statusCode,
                                message: errorMessage,
                                responseBody: data,
                                headers: headers
                            )
                            
                            continuation.resume(with: .failure(apiError))
                            return
                        }
                        
                        if debugResponse == true {
                            print("\(endpoint.path) response is \(String(decoding: data, as: UTF8.self))")
                        }
                        
                        let json = try JSONDecoder().decode(T.self, from: data)
                        continuation.resume(with: .success(json))
                        
                    } catch let decodingError as DecodingError {
                        let endpointDesc = self.safeEndpointDescription(endpoint)
                        let message = "\(endpointDesc) \(decodingError.localizedDescription)"
                        continuation.resume(with: .failure(APIClientError(
                            statusCode: httpResponse.statusCode,
                            message: message,
                            responseBody: data ?? Data(),
                            headers: headers
                        )))
                    } catch {
                        let endpointDesc = self.safeEndpointDescription(endpoint)
                        let message = "\(endpointDesc) \(error.localizedDescription)"
                        continuation.resume(with: .failure(APIClientError(
                            statusCode: httpResponse.statusCode,
                            message: message,
                            responseBody: data ?? Data(),
                            headers: headers
                        )))
                    }
                }
                
               
                Task {
                    await taskActor.setTask(task)
                }
                
                task.resume()
            }
        } onCancel: {
            
            Task {
                await taskActor.cancel()
            }
        }
    }
    
    private func fetchWithRetry<T: Decodable>(type: T.Type?, _ endpoint: Endpoint, debugResponse: Bool?, attempt: Int) async throws -> T {
        try Task.checkCancellation()
        
        do {
            let result: T = try await performRequest(type: type, endpoint, debugResponse: debugResponse)
            await rateLimitState.markSuccessfulRequest()
            return result
            
        } catch is CancellationError {
            throw CancellationError()
            
        } catch let error as APIClientError {
            if error.statusCode == 401 {
                APIClient.onUnauthorized?()
                throw error
            }
            
            if error.statusCode == 429 {
                let serverRetryAfter = extractRetryAfter(from: error)
                let waitTime: TimeInterval
                
                if let retryAfter = serverRetryAfter {
                    waitTime = retryAfter
                    if debugResponse == true {
                        print("🔄 Server says wait \(retryAfter)s (Retry-After header)")
                    }
                } else {
                    waitTime = await calculateAdaptiveDelay(attempt: attempt)
                    if debugResponse == true {
                        print("🔄 No Retry-After header, using adaptive delay: \(waitTime)s")
                    }
                }
                
                await rateLimitState.markServerThrottled(duration: waitTime)
                
                if shouldRetry(attempt: attempt) {
                    if debugResponse == true {
                        print("429 Rate Limited - Retrying after \(waitTime)s (attempt \(attempt + 1)/\(rateLimitConfiguration.maxRetries + 1))")
                    }
                    
                    try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                    return try await fetchWithRetry(type: type, endpoint, debugResponse: debugResponse, attempt: attempt + 1)
                }
                
            } else if (500...599).contains(error.statusCode) && shouldRetry(attempt: attempt) {
                let delay = calculateDelay(attempt: attempt)
                
                if debugResponse == true {
                    print("Server error \(error.statusCode) - Retrying in \(delay)s")
                }
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await fetchWithRetry(type: type, endpoint, debugResponse: debugResponse, attempt: attempt + 1)
            }
            
            throw error
        }
    }
}
