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
    
  
    
    public func getFolderContent(folderId: String, debug: Bool?) async throws -> FetchFolderContentResponse {
        let endpoint = GetFolderContentEndpoint(path: "\(self.baseUrl)/storage/v2/folder/\(folderId)")
        
        return try await apiClient.fetch(type: FetchFolderContentResponse.self, endpoint, debugResponse: debug)
    }
    
    
    /// Creates a folder inside the parentFolderId given with the given name
    public func createFolder(parentFolderId: Int, folderName: String, debug: Bool?) async throws -> CreateFolderResponse {
        let endpoint = CreateFolderEndpoint(path: "\(self.baseUrl)/storage/folder", body: CreateFolderPayload(parentFolderId: parentFolderId, folderName: folderName).toJson())
        
        return try await apiClient.fetch(type: CreateFolderResponse.self, endpoint, debugResponse: debug)
    }
    
    
    /// Given a folderId, updates the folder name, if the folder name conflicts with
    /// the remove folder name, an ApiClientError with 409 statusCode is throw
    
    public func updateFolder(folderId: String, folderName: String, debug: Bool?) async throws -> UpdateFolderResponse {
        let endpoint = UpdateFolderEndpoint(path: "\(self.baseUrl)/storage/folder/\(folderId)/meta", body: UpdateFolderPayload(
            metadata: MetadataUpdatePayload(itemName: folderName)
        ).toJson())
        
        return try await apiClient.fetch(type: UpdateFolderResponse.self, endpoint, debugResponse: debug)
    }
    
    public func trashItems() {
        
    }
}
