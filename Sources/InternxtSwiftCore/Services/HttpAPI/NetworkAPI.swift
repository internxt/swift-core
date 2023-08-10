//
//  NetworkAPI.swift
//  
//
//  Created by Robert Garcia on 4/8/23.
//

import Foundation


@available(macOS 10.15, *)
public struct NetworkAPI {
    private let baseUrl: String
    private let apiClient: APIClient

    public init(baseUrl: String, basicAuthToken: String) {
        self.baseUrl = baseUrl
        self.apiClient = APIClient(urlSession: URLSession.shared, authorizationHeaderValue: "Basic \(basicAuthToken)")
    }
    
    public func startUpload(bucketId: String,  uploadSize: Int,parts: Int = 1, debug: Bool = true) async throws -> StartUploadResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/v2/buckets/\(bucketId)/files/start?multiparts=\(String(parts))",
            method: .POST,
            body: StartUploadPayload(
                uploads: [NetworkUploadPayload(
                    index: 0,
                    size: uploadSize
                )]
            ).toJson()
        )
        
        return try await apiClient.fetch(type: StartUploadResponse.self, endpoint, debugResponse: debug)
    }
    
    public func finishUpload(bucketId: String, payload: FinishUploadPayload, debug: Bool = true) async throws -> FinishUploadResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/v2/buckets/\(bucketId)/files/finish",
            method: .POST,
            body: payload.toJson()
        )
        return try await apiClient.fetch(type: FinishUploadResponse.self, endpoint, debugResponse: debug)
    }
    
    
    public func getFileInfo(bucketId: String, fileId: String) {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/v2/buckets/\(bucketId)/files/\(fileId)/info"
        )
    
    }
}
