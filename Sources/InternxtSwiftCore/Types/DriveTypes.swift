//
//  DriveTypes.swift
//  
//
//  Created by Robert Garcia on 6/8/23.
//

import Foundation

public struct GetFolderFilesResult: Decodable {
    public let id: Int
    public let fileId: String
    public let name: String
    public let type: String?
    // Size string in bytes
    public let size: String
    public let bucket: String
    public let folderId: Int
    public let encryptVersion: String?
    public let deleted: Bool
    // ISO string
    public let deletedAt: String?
    public let userId: Int
    public let modificationTime: String
    // ISO string
    public let createdAt: String
    // ISO string
    public let updatedAt: String
    public let plainName: String?
    public let removed: Bool
    // ISO string
    public let removedAt: String?
    public let status: String
    public let uuid: String
}

public struct GetFolderFilesResponse: Decodable {
    public let result: Array<GetFolderFilesResult>
}

public struct GetFolderFoldersResult: Decodable {
    public let type: String?
    public let id: Int
    public let parentId: Int?
    public let name: String
    public let userId: Int
    public let encryptVersion: String?
    public let deleted: Bool
    // ISO string
    public let deletedAt: String?
    // ISO string
    public let createdAt: String
    // ISO string
    public let updatedAt: String
    public let plainName: String?
    public let removed: Bool
    // ISO string
    public let removedAt: String?
}

public struct GetFolderFoldersResponse: Decodable {
    public let result: Array<GetFolderFoldersResult>
}


public struct CreateFolderPayload: Encodable {
    public let parentFolderId: Int
    public let folderName: String
    init(parentFolderId: Int, folderName: String)  {
        self.parentFolderId = parentFolderId
        self.folderName = folderName
    }
}
public struct CreateFolderResponse: Decodable {
    public let bucket: String?
    public let id: Int
    public let name: String
    public let plain_name: String?
    public let parentId: Int?
    // ISO Date
    public let createdAt: String
    public let updatedAt: String
    public let userId: Int
}


public struct UpdateFolderResponse: Decodable {
    public let id: Int
    public let name: String
}

public struct FolderMetadataUpdatePayload: Encodable {
    public let itemName: String
}


public struct UpdateFolderPayload: Encodable {
    public let metadata: FolderMetadataUpdatePayload
}

public struct FileMetadataUpdatePayload: Encodable {
    public let itemName: String
}


public struct UpdateFilePayload: Encodable {
    public let bucketId: String
    public let metadata: FileMetadataUpdatePayload
    public let relativePath: String = NSUUID().uuidString
}

public struct UpdateFileResponse: Decodable {
    public let plain_name: String
}


public struct GetFolderMetaByIdResponse: Decodable {
    public let id: Int
    public let parentId: Int?
    public let name: String
    public let bucket: String?
    public let userId: Int
    public let encryptVersion: String?
    public let deleted: Bool
    // ISO Date
    public let createdAt: String
    public let updatedAt: String
    public let deletedAt: String?
    public let removedAt: String?
    public let uuid: String?
    public let plainName: String?
    public let removed: Bool
}

public struct GetFileMetaByIdResponse: Decodable {
    public let id: Int
    public let fileId: String
    public let folderId: Int
    public let name: String
    public let type: String?
    public let size: String
    public let bucket: String
    public let deleted: Bool
    public let deletedAt: String?
    public let userId: Int
    public let modificationTime: String
    public let createdAt: String
    public let updatedAt: String
    public let uuid: String
    public let plainName: String?
    public let removed: Bool?
    public let removedAt: String?
    public let status: String
}


public struct CreateFileData: Encodable {
    public let fileId: String
    public let type: String?
    public let bucket: String
    public let size: Int
    public let folder_id: Int
    public let name: String?
    public let plain_name: String
    public let encrypt_version: String
    
    public init(fileId: String, type: String?, bucket: String, size: Int, folderId: Int, name: String?, plainName: String, encryptVersion: String = "03-aes") {
        self.fileId = fileId
        self.type = type
        self.bucket = bucket
        self.size = size
        self.folder_id = folderId
        self.name = name
        self.plain_name = plainName
        self.encrypt_version = encryptVersion
    }
}

public struct CreateFilePayload: Encodable {
    public let file: CreateFileData
}

public struct CreateFileResponse: Decodable {
    public let created_at: String
    public let deleted: Bool
    public let status: String
    public let id: Int
    public let name: String
    public let plain_name: String?
    public let type: String?
    public let size: String?
    public let folderId: Int
    public let fileId: String
    public let bucket: String
    public let encrypt_version: String
    public let userId: Int
    public let modificationTime: String
    public let updatedAt: String
    public let createdAt: String
    public let deletedAt: String?
    public let uuid: String
}

public struct DriveUser: Codable {
    public let email: String
    public let avatar: String?
    public let bridgeUser: String
    public let bucket: String
    public let createdAt: String
    public let name: String
    public let lastname: String
    public let root_folder_id: Int
    public let userId: String
    public let username: String
    public let uuid: String
}

public struct RefreshUserResponse: Decodable {
    public let token: String
    public let user: DriveUser
}


public struct MoveFilePayload: Encodable {
    public let bucketId: String
    public let destination: Int
    public let fileId: String
    public let relativePath:String = NSUUID().uuidString
}


public struct MoveFileResponse: Decodable {
    public let moved: Bool
}


public struct MoveFolderPayload: Encodable {
    public let folderId: Int
    public let destination: Int
}


public struct MoveFolderResponse: Decodable {
    public let moved: Bool
}


public struct GetLimitResponse: Decodable {
    public let maxSpaceBytes: Int
}


public struct GetDriveUsageResponse: Decodable {
    public let total: Int
    public let drive: Int
    public let backups: Int
}
