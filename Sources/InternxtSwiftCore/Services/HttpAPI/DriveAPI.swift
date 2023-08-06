//
//  DriveApi.swift
//  
//
//  Created by Robert Garcia on 1/8/23.
//

import Foundation

@available(macOS 10.15, *)
public struct DriveAPI {
    private let apiClient: APIClient
    private let configLoader = ConfigLoader()
    
    public init(authToken: String) {
        self.apiClient = APIClient(urlSession: URLSession.shared, token: authToken)
    }
    struct GetFolderContentEndpoint: Endpoint {
        let body: Codable? = nil
        let method =  HTTPMethod.GET
    }
    
    public func getFolderContent(folderId: String) async throws -> FetchFolderContentResponse {
        let base = try configLoader.getConfigProperty(configKey: "DRIVE_URL")
        
        let path =   "\(base)/storage/v2/folder/\(folderId)"
        let endpoint = GetFolderContentEndpoint()
        
        return try await apiClient.fetch(type: FetchFolderContentResponse.self, endpoint)
    }
}
