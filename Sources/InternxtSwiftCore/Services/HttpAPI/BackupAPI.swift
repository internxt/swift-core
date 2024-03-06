//
//  BackupAPI.swift
//  
//
//  Created by Richard Ascanio on 1/18/24.
//

import Foundation

@available(macOS 10.15, *)
public struct BackupAPI {
    private let baseUrl: String
    private let apiClient: APIClient
    private let driveAPI: DriveAPI

    public init(baseUrl: String, authToken: String, clientName: String, clientVersion: String) {
        self.baseUrl = baseUrl
        self.apiClient = APIClient(urlSession: URLSession.shared, authorizationHeaderValue: "Bearer \(authToken)", clientName: clientName, clientVersion: clientVersion)
        self.driveAPI = DriveAPI(baseUrl: baseUrl, authToken: authToken, clientName: clientName, clientVersion: clientVersion)
    }

    public func getAllDevices(debug: Bool = false) async throws -> DevicesResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/backup/deviceAsFolder",
            method: .GET
        )

        return try await apiClient.fetch(type: DevicesResponse.self, endpoint, debugResponse: debug)
    }

    public func addDeviceAsFolder(deviceName: String, debug: Bool = false) async throws -> DeviceAsFolder {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/backup/deviceAsFolder",
            method: .POST,
            body: CreateDevicePayload(deviceName: deviceName).toJson()
        )

        return try await apiClient.fetch(type: DeviceAsFolder.self, endpoint, debugResponse: debug)
    }

    public func getBackupChilds(folderId: String, offset: Int = 0, limit: Int = 50, sort: String = "ASC", debug: Bool = false) async throws -> GetFolderFoldersResponse {
        return try await driveAPI.getFolderFolders(folderId: folderId, offset: offset, limit: limit, sort: sort, debug: debug)
    }

    public func getBackupFiles(folderId: String, offset: Int = 0, limit: Int = 50, sort: String = "ASC", debug: Bool = false) async throws -> GetFolderFilesResponse {
        return try await driveAPI.getFolderFiles(folderId: folderId, offset: offset, limit: limit, sort: sort, debug: debug)
    }

    public func createBackupFolder(parentFolderId: Int, folderName: String, debug: Bool = false) async throws -> CreateFolderResponse {
        return try await driveAPI.createFolder(parentFolderId: parentFolderId, folderName: folderName, debug: debug)
    }

    public func createBackupFile(createFileData: CreateFileData, debug: Bool = false) async throws -> CreateFileResponse {
        return try await driveAPI.createFile(createFile: createFileData, debug: debug)
    }

    public func deleteBackupFolder(folderId: Int, debug: Bool = false) async throws -> Bool {
        return try await driveAPI.deleteFolder(folderId: folderId, debug: debug)
    }

    public func replaceFileId(fileUuid: String, newFileId: String, newSize: Int, debug: Bool = false) async throws -> ReplaceFileResponse {
        return try await driveAPI.replaceFileId(fileUuid: fileUuid, newFileId: newFileId, newSize: newSize, debug: debug)
    }
}
