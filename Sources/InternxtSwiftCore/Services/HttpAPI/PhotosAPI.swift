//
//  PhotosAPI.swift
//  
//
//  Created by Robert Garcia on 5/9/23.
//

import Foundation

@available(macOS 10.15, *)
public struct PhotosAPI {
    private let baseUrl: String
    private let apiClient: APIClient
    
    public init(baseUrl: String, authToken: String) {
        self.baseUrl = baseUrl
        self.apiClient = APIClient(urlSession: URLSession.shared, authorizationHeaderValue: "Bearer \(authToken)")
    }
    
    public func getUsage(debug: Bool = false) async throws -> GetPhotosUsageResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/photos/usage",
            method: .GET
        )
        
        return try await apiClient.fetch(type: GetPhotosUsageResponse.self, endpoint, debugResponse: debug)
    }
}
