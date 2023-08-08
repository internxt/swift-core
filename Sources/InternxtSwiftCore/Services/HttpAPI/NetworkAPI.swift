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

    public init(baseUrl: String, authToken: String) {
        self.baseUrl = baseUrl
        self.apiClient = APIClient(urlSession: URLSession.shared, token: authToken)
    }
    
    func startUpload(bucketId: String,  uploadSize: Int,parts: Int = 1, debug: Bool = false) async throws -> UploadResult? {
        let path =   "\(self.baseUrl)/v2/buckets/\(bucketId)/files/start?multiparts=\(String(parts))"
        let endpoint = StartUploadEndpoint(body: StartUploadPayload(
            uploads: [NetworkUploadPayload(
                index: 0,
                size: uploadSize
            )]
        ).toJson())
        
        return try await apiClient.fetch(type: UploadResult.self, endpoint, debugResponse: debug)
    }
}
