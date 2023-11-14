//
//  NetworkFacadeTests.swift
//  InternxtSwiftCoreTests
//
//  Created by Robert Garcia on 11/8/23.
//

import XCTest
@testable import InternxtSwiftCore



final class NetworkFacadeTests: XCTestCase {
    static let apiURL = URL(string: "https://network-api.com")!
    static func getTestingNetworkFacade() ->  NetworkFacade {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockedUrlSession = URLSession.init(configuration: configuration)
        
        return NetworkFacade(
            mnemonic: "group food control own donate safe hybrid beauty menu relax maze lamp element camp game kitten ladder much tattoo ivory sister cinnamon orbit sea",
            networkAPI: NetworkAPI(
                baseUrl: apiURL.absoluteString,
                basicAuthToken: "BasicAuthToken",
                urlSession: mockedUrlSession,
                clientName: "drive-desktop-testing-mode",
                clientVersion: "test"
            ),
            urlSession: mockedUrlSession
        )
    }
    var sut: NetworkFacade = getTestingNetworkFacade()
    
    
    override func setUpWithError() throws {
        sut = NetworkFacadeTests.getTestingNetworkFacade()
    }
    
    func getTemporaryDestination() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory() + "/test_\(UUID())")
    }

    func testFailUploadIfBucketNotHex() async throws {
        let destination = getTemporaryDestination()
        let inputStream = InputStream.init(data: "test".data(using: .utf8)!)
        do {
            _ = try await sut.uploadFile(input: inputStream, encryptedOutput: destination, fileSize: 100, bucketId: "bucket123", progressHandler: {_ in})
        } catch {
            
            XCTAssertEqual(error as? ExtensionError,  ExtensionError.InvalidHex)
        }
        
    }
    
    func testFailUploadIfEncryptedSizeIsNotTheSameAsOriginal() async throws {
        let destination = getTemporaryDestination()
        let inputStream = InputStream.init(data: "test".data(using: .utf8)!)
       
        do {
            _ = try await sut.uploadFile(input: inputStream, encryptedOutput: destination, fileSize: 100, bucketId: "93535c0bfff5de6d59c8eec72b46b605", progressHandler: {_ in})
        } catch {
            XCTAssertTrue(error is NetworkFacadeError)
            XCTAssertEqual(error as? NetworkFacadeError,  NetworkFacadeError.EncryptedFileNotSameSizeAsOriginal)
        }
    }
    
    func testShouldThrowAnErrorIfTheFileUploadStartsFail() async throws {
        let errorMessage = "Internal server error"
        MockURLProtocol.requestHandler = { request in
            
            let response = HTTPURLResponse(url: NetworkFacadeTests.apiURL, statusCode: 500, httpVersion: nil, headerFields: nil)!
            let data = errorMessage.data(using: .utf8)
            return (response, data)
        }
        let destination = getTemporaryDestination()
        let inputStream = InputStream.init(data: "test".data(using: .utf8)!)
       
        do {
            _ = try await sut.uploadFile(input: inputStream, encryptedOutput: destination, fileSize: 4, bucketId: "93535c0bfff5de6d59c8eec72b46b605", progressHandler: {_ in})
        } catch {
            XCTAssertTrue(error is StartUploadError)
            let uploadError: StartUploadError = (error as? StartUploadError)!
            
            XCTAssertEqual(uploadError.apiError?.statusCode, 500)
            XCTAssertEqual(String(data: uploadError.apiError!.responseBody, encoding: .utf8), errorMessage)
           
        }
    }
    
    
    func testShouldThrowAnErrorIfTheUploadedSizeDoesntMatchTheFileSize() async throws {

        MockURLProtocol.requestHandler = { request in
            let url = request.url
                        
            // Start upload, don't fail
            if url?.lastPathComponent == "start" {
                let response = HTTPURLResponse(url: NetworkFacadeTests.apiURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
                
                let data = """
                {
                    "uploads": [
                        {
                            "index": 0,
                            "uuid": "uuid",
                            "url": "https://upload.com/uploadId",
                            "urls": null
                        }
                    ]
                }
                """.data(using: .utf8)!
                
                return (response, data)
            }
            
            
            if url?.lastPathComponent == "uploadId" {
                let data = Data()
                let response = HTTPURLResponse(url: NetworkFacadeTests.apiURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, data)
            }
            
            if url?.lastPathComponent == "finish" {
                let data = """
                {
                    "bucket": "93535c0bfff5de6d59c8eec72b46b605",
                    "index": "3d8339eca557e98d5e78a8eab94521d6dd4ff35fce32ee01fcc16eb7676ceb3f",
                    "size": 3,
                    "version": 2,
                    "created": "2023-08-11T18:02:22.191Z",
                    "renewal": "2023-11-09T18:02:22.191Z",
                    "mimetype": "application/octet-stream",
                    "filename": "651eb0bb-c4ae-457e-9cdb-6daf2674985a",
                    "id": "64d677aeed70fe00082983bc"
                }

                """.data(using: .utf8)
                let response = HTTPURLResponse(url: NetworkFacadeTests.apiURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, data)
            }

            let response = HTTPURLResponse(url: NetworkFacadeTests.apiURL, statusCode: 500, httpVersion: nil, headerFields: nil)!
            let data = Data()
            return (response, data)
        }
        let destination = getTemporaryDestination()
        let inputStream = InputStream.init(data: "test".data(using: .utf8)!)
       
        do {
            _ = try await sut.uploadFile(input: inputStream, encryptedOutput: destination, fileSize: 4, bucketId: "93535c0bfff5de6d59c8eec72b46b605", progressHandler: {_ in})
        } catch {
            XCTAssertTrue(error is UploadError)
            XCTAssertEqual(error as? UploadError, UploadError.UploadedSizeNotMatching)
           
        }
    }
    
    func testShouldReturnTheUploadedObjectIfAllOperationsSuccess() async throws {

        MockURLProtocol.requestHandler = { request in
            let url = request.url
                        
            // Start upload, don't fail
            if url?.lastPathComponent == "start" {
                let response = HTTPURLResponse(url: NetworkFacadeTests.apiURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
                
                let data = """
                {
                    "uploads": [
                        {
                            "index": 0,
                            "uuid": "uuid",
                            "url": "https://upload.com/uploadId",
                            "urls": null
                        }
                    ]
                }
                """.data(using: .utf8)!
                
                return (response, data)
            }
            
            
            if url?.lastPathComponent == "uploadId" {
                let data = Data()
                let response = HTTPURLResponse(url: NetworkFacadeTests.apiURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, data)
            }
            
            if url?.lastPathComponent == "finish" {
                let data = """
                {
                    "bucket": "93535c0bfff5de6d59c8eec72b46b605",
                    "index": "3d8339eca557e98d5e78a8eab94521d6dd4ff35fce32ee01fcc16eb7676ceb3f",
                    "size": 4,
                    "version": 2,
                    "created": "2023-08-11T18:02:22.191Z",
                    "renewal": "2023-11-09T18:02:22.191Z",
                    "mimetype": "application/octet-stream",
                    "filename": "651eb0bb-c4ae-457e-9cdb-6daf2674985a",
                    "id": "uploadedFileId"
                }

                """.data(using: .utf8)
                let response = HTTPURLResponse(url: NetworkFacadeTests.apiURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, data)
            }

            let response = HTTPURLResponse(url: NetworkFacadeTests.apiURL, statusCode: 500, httpVersion: nil, headerFields: nil)!
            let data = Data()
            return (response, data)
        }
        let destination = getTemporaryDestination()
        let inputStream = InputStream.init(data: "test".data(using: .utf8)!)
       
        
        let uploadedResult = try await sut.uploadFile(input: inputStream, encryptedOutput: destination, fileSize: 4, bucketId: "93535c0bfff5de6d59c8eec72b46b605", progressHandler: {_ in})
        
        XCTAssertEqual(uploadedResult.id, "uploadedFileId")
    }
    
    func testShouldFailIfHashIsNotMatching() async throws {
        let destination = getTemporaryDestination()
        let contentURL = getTemporaryDestination()
        // Write into the file
        try "filedata".data(using: .utf8)?.write(to: contentURL)
        
        let downloadResult = DownloadResult(url: contentURL, expectedContentHash: "4ae6fcc4dd6ebcdb9076f2396d64da48", index: "2ec6d83f8987fe2bd04d0260208521d49d4c79187d71989a16ca79d41b90b8f1")
        
        do {
            _ = try await sut.decryptFile(bucketId: "93535c0bfff5de6d59c8eec72b46b605", destinationURL: destination, progressHandler: {_ in }, encryptedFileDownloadResult: downloadResult)
        } catch {
            
            XCTAssertEqual(error as? NetworkFacadeError, NetworkFacadeError.HashMissmatch)
        }
    }
    
    func testShouldFailIfFileIsEmpty() async throws {
        let destination = getTemporaryDestination()
        let contentURL = getTemporaryDestination()
       
        
        let downloadResult = DownloadResult(url: contentURL, expectedContentHash: "4ae6fcc4dd6ebcdb9076f2396d64da48", index: "2ec6d83f8987fe2bd04d0260208521d49d4c79187d71989a16ca79d41b90b8f1")
        
        do {
            _ = try await sut.decryptFile(bucketId: "93535c0bfff5de6d59c8eec72b46b605", destinationURL: destination, progressHandler: {_ in }, encryptedFileDownloadResult: downloadResult)
        } catch {
            
            XCTAssertEqual(error as? NetworkFacadeError, NetworkFacadeError.FileIsEmpty)
        }
    }
}
