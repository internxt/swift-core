//
//  NetworkAPI.swift
//  
//
//  Created by Robert Garcia on 4/8/23.
//

import Foundation


@available(macOS 10.15, *)
public struct NetworkAPI {
    private let apiClient = APIClient()
    private let configLoader = CoreConfigLoader()
    
    func startUpload(bucketId: String,  uploadSize: Int,parts: Int = 1) async throws -> UploadResult? {
        let base = try configLoader.getConfigProperty(configKey: "NETWORK_URL")
        let path =   "\(base)/v2/buckets/\(bucketId)/files/start?multiparts=\(String(parts))"
        let endpoint = StartUploadEndpoint(body: StartUploadPayload(
            uploads: [NetworkUploadPayload(
                index: 0,
                size: uploadSize
            )]
        ))
        
        return try await apiClient.fetch(type: UploadResult.self, endpoint)
    }
}
