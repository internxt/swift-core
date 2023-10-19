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
        self.apiClient = APIClient(urlSession: URLSession.shared, authorizationHeaderValue: "Bearer \(authToken)")
    }
    
    /// Get paginated files inside the given folder
    public func getFolderFiles(folderId: String, offset: Int = 0, limit: Int = 50, sort: String = "ASC", debug: Bool = false) async throws -> GetFolderFilesResponse {
        
        let query: String = "?offset=\(String(offset))&limit=\(String(limit))&sort=\(sort)"
        let endpoint = Endpoint(path: "\(self.baseUrl)/folders/\(folderId)/files\(query)")
        
        return try await apiClient.fetch(type: GetFolderFilesResponse.self, endpoint, debugResponse: debug)
    }
    
    /// Get paginated folders inside the given folder
    public func getFolderFolders(folderId: String, offset: Int = 0, limit: Int = 50, sort: String = "ASC", debug: Bool = false) async throws -> GetFolderFoldersResponse {
        let query: String = "?offset=\(String(offset))&limit=\(String(limit))&sort=\(sort)"
        let endpoint = Endpoint(path: "\(self.baseUrl)/folders/\(folderId)/folders\(query)")
        
        return try await apiClient.fetch(type: GetFolderFoldersResponse.self, endpoint, debugResponse: debug)
    }
    
    
    /// Creates a folder inside the given parentFolderId with the given name
    public func createFolder(parentFolderId: Int, folderName: String, debug: Bool = false) async throws -> CreateFolderResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/storage/folder",
            method: .POST,
            body: CreateFolderPayload(parentFolderId: parentFolderId, folderName: folderName).toJson()
        )
        
        return try await apiClient.fetch(type: CreateFolderResponse.self, endpoint, debugResponse: debug)
    }
    
    /// Creates a file inside the given parentFolderId with the given name
    public func createFile(createFile: CreateFileData, debug: Bool = false) async throws -> CreateFileResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/storage/file",
            method: .POST,
            body: CreateFilePayload(file: createFile).toJson()
        )
        
        return try await apiClient.fetch(type: CreateFileResponse.self, endpoint, debugResponse: debug)
    }
    
    public func createThumbnail(createThumbnail: CreateThumbnailData, debug: Bool = false) async throws -> CreateThumbnailResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/storage/thumbnail",
            method: .POST,
            body: CreateThumbnailPayload(thumbnail: createThumbnail).toJson()
        )
        
        return try await apiClient.fetch(type: CreateThumbnailResponse.self, endpoint, debugResponse: debug)
    }
    
    /// Given a folderId, updates the folder name, if the folder name conflicts with
    /// the remove folder name, an ApiClientError with 409 statusCode is throw
    
    public func updateFolder(folderId: String, folderName: String, debug: Bool = false) async throws -> UpdateFolderResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/storage/folder/\(folderId)/meta",
            method: .POST,
            body: UpdateFolderPayload(
                    metadata: FolderMetadataUpdatePayload(itemName: folderName)
                    ).toJson()
        )
        
        return try await apiClient.fetch(type: UpdateFolderResponse.self, endpoint, debugResponse: debug)
    }
    
    /// Given a fileId, updates the file name

    public func updateFile(fileId: String, bucketId: String, newFilename: String, debug: Bool = false) async throws -> UpdateFileResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/storage/file/\(fileId)/meta",
            method: .POST,
            body: UpdateFilePayload(
                bucketId: bucketId,
                metadata: FileMetadataUpdatePayload(itemName: newFilename)
            ).toJson()
        )
        
        return try await apiClient.fetch(type: UpdateFileResponse.self, endpoint, debugResponse: debug)
    }
    
    public func getFolderMetaById(id: String, debug: Bool = false) async throws -> GetFolderMetaByIdResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/folders/\(id)/metadata",
            method: .GET
        )
        
        return try await apiClient.fetch(type: GetFolderMetaByIdResponse.self, endpoint, debugResponse: debug)
    }
    
    public func getFileMetaByUuid(uuid: String, debug: Bool = false)  async throws -> GetFileMetaByIdResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/files/\(uuid)/meta",
            method: .GET
        )
        
        return try await apiClient.fetch(type: GetFileMetaByIdResponse.self, endpoint, debugResponse: debug)
    }
    
    public func moveFile(fileId: String, bucketId: String, destinationFolder: Int, debug: Bool = false) async throws -> MoveFileResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/storage/move/file",
            method: .POST,
            body: MoveFilePayload(
                bucketId: bucketId,
                destination: destinationFolder,
                fileId: fileId
            ).toJson()
        )
    
        return try await apiClient.fetch(type: MoveFileResponse.self, endpoint, debugResponse: debug)
    }
    
    public func moveFolder(folderId: Int, destinationFolder: Int, debug: Bool = false) async throws -> MoveFolderResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/storage/move/folder",
            method: .POST,
            body: MoveFolderPayload(
                folderId: folderId,
                destination: destinationFolder
            ).toJson()
        )
    
        return try await apiClient.fetch(type: MoveFolderResponse.self, endpoint, debugResponse: debug)
    }
    
    public func refreshUser(debug: Bool = false) async throws -> RefreshUserResponse  {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/user/refresh",
            method: .GET
        )
        
        return try await apiClient.fetch(type: RefreshUserResponse.self, endpoint, debugResponse: debug)
    }
    
    public func getLimit(debug: Bool = false) async throws -> GetLimitResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/limit",
            method: .GET
        )
        
        return try await apiClient.fetch(type: GetLimitResponse.self, endpoint, debugResponse: debug)
    }
    
    public func getUsage(debug: Bool = false) async throws -> GetDriveUsageResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/usage",
            method: .GET
        )
        
        return try await apiClient.fetch(type: GetDriveUsageResponse.self, endpoint, debugResponse: debug)
    }
    
    public func getUpdatedFiles(
        updatedAt: Date,
        status: String = "ALL",
        limit: Int = 50,
        offset: Int = 0,
        debug: Bool = false
    ) async throws -> GetUpdatedFilesResponse {
        
       
        let dateFormatter =  ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        
        let formattedUpdatedAt =  dateFormatter.string(from: updatedAt)
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/files?updatedAt=\(formattedUpdatedAt)&status=\(status)&offset=\(offset)&limit=\(limit)",
            method: .GET
        )
        
    
        
        return try await apiClient.fetch(type: GetUpdatedFilesResponse.self, endpoint, debugResponse: debug)
    }
    
    public func getUpdatedFolders(
        updatedAt: Date,
        status: String = "ALL",
        limit: Int = 50,
        offset: Int = 0,
        debug: Bool = false
    ) async throws -> GetUpdatedFoldersResponse {
        
       
        let dateFormatter =  ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        
        let formattedUpdatedAt =  dateFormatter.string(from: updatedAt)
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/folders?updatedAt=\(formattedUpdatedAt)&status=\(status)&offset=\(offset)&limit=\(limit)",
            method: .GET
        )
        
    
        
        return try await apiClient.fetch(type: GetUpdatedFoldersResponse.self, endpoint, debugResponse: debug)
    }
    
}
