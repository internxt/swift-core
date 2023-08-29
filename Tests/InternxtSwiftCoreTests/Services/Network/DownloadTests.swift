//
//  DownloadTests.swift
//  InternxtSwiftCoreTests
//
//  Created by Robert Garcia on 29/8/23.
//

import XCTest
@testable import InternxtSwiftCore
final class DownloadTests: XCTestCase {
    
    static let apiURL = URL(string: "https://network-api.com")!
    
    static func getTestingDownloadModule() ->  Download {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockedUrlSession = URLSession.init(configuration: configuration)
        return Download(
            networkAPI: NetworkAPI(
                baseUrl: apiURL.absoluteString,
                basicAuthToken: "BasicAuthToken",
                urlSession: mockedUrlSession
            ),
            urlSession: mockedUrlSession
        )
    }
    
    func getTemporaryDestination() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory() + "/test_\(UUID())")
    }
    
    var sut: Download = getTestingDownloadModule()
    
    override func setUpWithError() throws {
        sut = DownloadTests.getTestingDownloadModule()
    }

    func testShouldFailIfBucketIdNotValid() async throws {
        let destination = getTemporaryDestination()
        do {
            _ = try await sut.start(bucketId: "bucketNotBucket", fileId: "file123", destination: destination)
        } catch {
            XCTAssertEqual(error as? DownloadError,  DownloadError.InvalidBucketId)
        }
        
    }
    
    // Multipart check until we implement it
    func testShouldFailIfMultipartIsReceived() async throws {
        let destination = getTemporaryDestination()
        MockURLProtocol.requestHandler = { request in
            let data = """
            {
                "bucket": "e8f6c43b49d72e21aa6094f0",
                "index": "2ec6d83f8987fe2bd04d0260208521d49d4c79187d71989a16ca79d41b90b8f1",
                "size": 30648,
                "version": 2,
                "created": "2023-08-16T10:51:34.592Z",
                "renewal": "2023-11-14T10:51:34.592Z",
                "mimetype": "application/octet-stream",
                "filename": "9dac6039-7ffd-4c8b-ad39-4779e5b3b4b4",
                "id": "64dcaa364a45bf00082ef12c",
                "shards": [
                    {
                        "index": 0,
                        "hash": "f754a1013f2fa5fe26ecbd9f159e81a616a89648",
                        "url": "https://s3.gra.io.cloud.ovh.net/files/d6d26a2b-c013-491e-a4c3-6f09dfbd7cbd?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=d0999b3fc01c4946a4b9f1dc49b22e9d%2F20230829%2Fgra%2Fs3%2Faws4_request&X-Amz-Date=20230829T172955Z&X-Amz-Expires=3600&X-Amz-Signature=6bad8c8b067b4d3704967c7b353dc3f29b1b67660ee91d74ef3e2451fad0a7fd&X-Amz-SignedHeaders=host"
                    },
                    {
                        "index": 1,
                        "hash": "f754a1013f2fa5fe26ecbd9f159e81a616a89788",
                        "url": "https://s3.gra.io.cloud.ovh.net/files/d6d26a2b-c013-491e-a4c3-6f09dfbd7cbd?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=d0999b3fc01c4946a4b9f1dc49b22e9d%2F20230829%2Fgra%2Fs3%2Faws4_request&X-Amz-Date=20230829T172955Z&X-Amz-Expires=3600&X-Amz-Signature=6bad8c8b067b4d3704967c7b353dc3f29b1b67660ee91d74ef3e2451fad0a7fd&X-Amz-SignedHeaders=host"
                    }
                ]
            }
            """.data(using: .utf8)!
            
            
            let response = HTTPURLResponse(url: NetworkFacadeTests.apiURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
        
        do {
            _ = try await sut.start(bucketId: "93535c0bfff5de6d59c8eec72b46b605", fileId: "64d677aeed70fe00082983bc", destination: destination)
        } catch {
            XCTAssertEqual(error as? DownloadError,  DownloadError.MultipartDownloadNotSupported)
        }
    }
    
    func testShouldCopyTheFileUrlIfOneIsDownloaded() async throws {
        let destination = getTemporaryDestination()
        let fakeDownloadUrl = getTemporaryDestination()
        let fileContent = "test".data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            
            if request.url?.lastPathComponent == "info" {
                let data = """
                {
                    "bucket": "e8f6c43b49d72e21aa6094f0",
                    "index": "2ec6d83f8987fe2bd04d0260208521d49d4c79187d71989a16ca79d41b90b8f1",
                    "size": 30648,
                    "version": 2,
                    "created": "2023-08-16T10:51:34.592Z",
                    "renewal": "2023-11-14T10:51:34.592Z",
                    "mimetype": "application/octet-stream",
                    "filename": "9dac6039-7ffd-4c8b-ad39-4779e5b3b4b4",
                    "id": "64dcaa364a45bf00082ef12c",
                    "shards": [
                        {
                            "index": 0,
                            "hash": "f754a1013f2fa5fe26ecbd9f159e81a616a89648",
                            "url": "\(fakeDownloadUrl.absoluteString)"
                        }
                    ]
                }
                """.data(using: .utf8)!
                
                
                let response = HTTPURLResponse(url: NetworkFacadeTests.apiURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, data)
            }
            
            // Return the file Data
            let response = HTTPURLResponse(url: NetworkFacadeTests.apiURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, fileContent)
        }
        
        _ = try await sut.start(bucketId: "93535c0bfff5de6d59c8eec72b46b605", fileId: "64d677aeed70fe00082983bc", destination: destination)
        
        let data: Data = try Data(contentsOf: destination)
        let result = String(decoding: data, as: UTF8.self)
        
        XCTAssertEqual(result, String(decoding: fileContent, as: UTF8.self))
    }

}
