//
//  DriveApi.swift
//  
//
//  Created by Robert Garcia on 1/8/23.
//

import Foundation

@available(macOS 10.15, *)
public struct DriveAPI {
    private let baseUrl: String
    private let apiClient: APIClient
    
    public init(baseUrl: String, authToken: String) {
        self.baseUrl = baseUrl
        self.apiClient = APIClient(urlSession: URLSession.shared, token: authToken)
    }
    
    struct GetFolderContentEndpoint: Endpoint {
        let body: Codable? = nil
        let method =  HTTPMethod.GET
        let path: String
        init(path: String) {
            self.path = path
        }
    }
    
    public func getFolderContent(folderId: String) async throws -> FetchFolderContentResponse {
        let endpoint = GetFolderContentEndpoint(path: "\(self.baseUrl)/storage/v2/folder/\(folderId)")
        
        return try await apiClient.fetch(type: FetchFolderContentResponse.self, endpoint)
    }
}
