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

    public init(baseUrl: String, authToken: String, clientName: String, clientVersion: String, gatewayHeader: String? = nil) {
        self.baseUrl = baseUrl
        self.apiClient = APIClient(urlSession: APIClient.ephemeralSession, authorizationHeaderValue: "Bearer \(authToken)", clientName: clientName, clientVersion: clientVersion
            ,authorizationHeaderGatewayValue: gatewayHeader)
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

    public func editDeviceName(deviceId: Int, deviceName: String, debug: Bool = false) async throws -> DeviceAsFolder {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/backup/deviceAsFolder/\(deviceId)",
            method: .PATCH,
            body: EditDevicePayload(deviceName: deviceName).toJson()
        )

        return try await apiClient.fetch(type: DeviceAsFolder.self, endpoint, debugResponse: debug)
    }
    
    public func editDeviceName(deviceUuid: String, deviceName: String, debug: Bool = false) async throws -> DeviceAsFolder {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/backup/deviceAsFolder/\(deviceUuid)",
            method: .PATCH,
            body: EditDevicePayload(deviceName: deviceName).toJson()
        )

        return try await apiClient.fetch(type: DeviceAsFolder.self, endpoint, debugResponse: debug)
    }
    
    public func getBackupChilds(folderUuid: String, offset: Int = 0, limit: Int = 50, order: String = "ASC", debug: Bool = false) async throws -> GetFolderFoldersResponseNew {
        return try await driveAPI.getFolderFolders(folderUuid: folderUuid, offset: offset, limit: limit, order: order, debug: debug)
    }


    public func getBackupFiles(folderUuid: String, offset: Int = 0, limit: Int = 50, order: String = "ASC", debug: Bool = false) async throws -> GetFolderFilesResponseV2 {
        return try await driveAPI.getFolderFilesV2(folderUuid: folderUuid, offset: offset, limit: limit, order: order, debug: debug)
    }

    public func createBackupFolder(parentFolderUuid: String, folderName: String, debug: Bool = false) async throws -> CreateFolderResponseNew {
        return try await driveAPI.createFolderNew(parentFolderUuid: parentFolderUuid, folderName: folderName, debug: debug)
    }

    public func createBackupFile(createFileData: CreateFileData, debug: Bool = false) async throws -> CreateFileResponse {
        return try await driveAPI.createFile(createFile: createFileData, debug: debug)
    }
    
    public func createBackupFileNew(createFileData: CreateFileDataNew, debug: Bool = false) async throws -> CreateFileResponseNew {
        return try await driveAPI.createFileNew(createFile: createFileData, debug: debug)
    }

    public func deleteBackupFolder(folderId: Int, debug: Bool = false) async throws -> Bool {
        return try await driveAPI.deleteFolderNew(folderId: folderId, debug: debug)
    }

    public func replaceFileId(fileUuid: String, newFileId: String?, newSize: Int, debug: Bool = false) async throws -> ReplaceFileResponse {
        return try await driveAPI.replaceFileId(fileUuid: fileUuid, newFileId: newFileId, newSize: newSize, debug: debug)
    }
    
    public func getExistenceFileInFolderByPlainName(uuid: String, files: Array<ExistenceFile>, debug: Bool = false) async throws  -> ExistenceFilesResponse {
        return try await driveAPI.getExistenceFileInFolderByPlainName(uuid: uuid, files: files)
    }
    
    public func getBackupFolderMeta(folderId: String, debug: Bool = false) async throws -> GetFolderMetaByIdResponse {
        return try await driveAPI.getFolderMetaById(id: folderId, debug: debug)
    }
}
