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
    
  
    
    public func getFolderFiles(folderId: String, offset: Int = 0, limit: Int = 50, sort: String = "ASC", debug: Bool = false) async throws -> GetFolderFilesResponse {
        
        let query: String = "?offset=\(String(offset))&limit=\(String(limit))&sort=\(sort)"
        let endpoint = GetFolderFilesEndpoint(path: "\(self.baseUrl)/folders/\(folderId)/files\(query)")
        
        return try await apiClient.fetch(type: GetFolderFilesResponse.self, endpoint, debugResponse: debug)
    }
    
    public func getFolderFolders(folderId: String, offset: Int = 0, limit: Int = 50, sort: String = "ASC", debug: Bool = false) async throws -> GetFolderFoldersResponse {
        let query: String = "?offset=\(String(offset))&limit=\(String(limit))&sort=\(sort)"
        let endpoint = GetFolderFoldersEndpoint(path: "\(self.baseUrl)/folders/\(folderId)/folders\(query)")
        
        return try await apiClient.fetch(type: GetFolderFoldersResponse.self, endpoint, debugResponse: debug)
    }
    
    
    /// Creates a folder inside the parentFolderId given with the given name
    public func createFolder(parentFolderId: Int, folderName: String, debug: Bool = false) async throws -> CreateFolderResponse {
        let endpoint = CreateFolderEndpoint(path: "\(self.baseUrl)/storage/folder", body: CreateFolderPayload(parentFolderId: parentFolderId, folderName: folderName).toJson())
        
        return try await apiClient.fetch(type: CreateFolderResponse.self, endpoint, debugResponse: debug)
    }
    
    
    /// Given a folderId, updates the folder name, if the folder name conflicts with
    /// the remove folder name, an ApiClientError with 409 statusCode is throw
    
    public func updateFolder(folderId: String, folderName: String, debug: Bool = false) async throws -> UpdateFolderResponse {
        let endpoint = UpdateFolderEndpoint(path: "\(self.baseUrl)/storage/folder/\(folderId)/meta", body: UpdateFolderPayload(
            metadata: MetadataUpdatePayload(itemName: folderName)
        ).toJson())
        
        return try await apiClient.fetch(type: UpdateFolderResponse.self, endpoint, debugResponse: debug)
    }
    
    public func trashItems() {
        
    }
}
