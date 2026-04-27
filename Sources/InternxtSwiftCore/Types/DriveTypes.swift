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
    public let deleted: Bool?
    // ISO string
    public let deletedAt: String?
    public let userId: Int
    public let modificationTime: String
    // ISO string
    public let createdAt: String
    // ISO string
    public let updatedAt: String
    public let plainName: String?
    public let removed: Bool?
    // ISO string
    public let removedAt: String?
    public let status: String
    public let uuid: String
}

public struct GetFolderFilesResultV2: Decodable {
    public let id: Int
    public let fileId: String?
    public let name: String?
    public let type: String?
    // Size string in bytes
    public let size: String
    public let bucket: String
    public let folderId: Int
    public let encryptVersion: String?
    public let deleted: Bool?
    // ISO string
    public let deletedAt: String?
    public let userId: Int
    public let modificationTime: String
    // ISO string
    public let createdAt: String
    // ISO string
    public let updatedAt: String
    public let plainName: String?
    public let removed: Bool?
    // ISO string
    public let removedAt: String?
    public let status: String
    public let uuid: String
}

public struct GetFolderFilesResponse: Decodable {
    public let result: Array<GetFolderFilesResult>
}

public struct GetFolderFilesResponseNew: Decodable {
    public let files: Array<GetFolderFilesResult>
}

public struct GetFolderFilesResponseV2: Decodable {
    public let files: Array<GetFolderFilesResultV2>
}

public struct GetFolderFoldersResult: Decodable {
    public let type: String?
    public let id: Int
    public let parentId: Int?
    public let name: String
    public let userId: Int
    public let encryptVersion: String?
    public let deleted: Bool?
    // ISO string
    public let deletedAt: String?
    // ISO string
    public let createdAt: String
    // ISO string
    public let updatedAt: String
    public let plainName: String?
    public let removed: Bool?
    // ISO string
    public let removedAt: String?
    public let status: String
    public let uuid: String?
}

public struct GetFolderFoldersResponse: Decodable {
    public let result: Array<GetFolderFoldersResult>
}

public struct GetFolderFoldersResponseNew: Decodable {
    public let folders: Array<GetFolderFoldersResult>
}



public struct CreateFolderPayload: Encodable {
    public let parentFolderId: Int
    public let folderName: String
    init(parentFolderId: Int, folderName: String)  {
        self.parentFolderId = parentFolderId
        self.folderName = folderName
    }
}

public struct CreateFolderPayloadNew: Encodable {
    public let parentFolderUuid: String
    public let plainName: String
    init(parentFolderUuid: String, folderName: String)  {
        self.parentFolderUuid = parentFolderUuid
        self.plainName = folderName
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

public struct CreateFolderResponseNew: Decodable {
    public let bucket: String?
    public let id: Int
    public let name: String
    public let plainName: String?
    public let parentId: Int?
    public let uuid: String
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

public struct FolderMetadataUpdatePayloadNew: Encodable {
    public let plainName: String
}


public struct UpdateFolderPayload: Encodable {
    public let metadata: FolderMetadataUpdatePayload
}

public struct FileMetadataUpdatePayload: Encodable {
    public let itemName: String
}

public struct FileMetadataUpdatePayloadNew: Encodable {
    public let plainName: String
}


public struct UpdateFilePayload: Encodable {
    public let bucketId: String
    public let metadata: FileMetadataUpdatePayload
    public let relativePath: String = NSUUID().uuidString
}

public struct UpdateFileResponse: Decodable {
    public let plain_name: String
}

public struct UpdateFileResponseNew: Decodable {
    public let plainName: String
}



public struct GetFolderMetaByIdResponse: Decodable {
    public let id: Int
    public let parentId: Int?
    public let name: String?
    public let bucket: String?
    public let userId: Int
    public let encryptVersion: String?
    public let deleted: Bool?
    // ISO Date
    public let createdAt: String
    public let updatedAt: String
    public let deletedAt: String?
    public let removedAt: String?
    public let uuid: String?
    public let plainName: String?
    public let removed: Bool?
    public let parentUuid: String?
}

public struct GetFileMetaByIdResponse: Decodable {
    public let id: Int
    public let fileId: String
    public let folderId: Int
    public let name: String
    public let type: String?
    public let size: String
    public let bucket: String
    public let deleted: Bool?
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
    public let folderUuid: String?
}

public struct GetFileMetaByIdResponseV2: Decodable {
    public let id: Int
    public let fileId: String?
    public let folderId: Int
    public let name: String
    public let type: String?
    public let size: String
    public let bucket: String
    public let deleted: Bool?
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
    public let folderUuid: String?
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

public struct CreateFileDataNew: Encodable {
    public let fileId: String?
    public let type: String?
    public let bucket: String
    public let size: Int
    public let folder_id: Int
    public let name: String?
    public let plain_name: String
    public let encrypt_version: String
    public let folderUuid: String?
    
    public init(fileId: String?, type: String?, bucket: String, size: Int, folderId: Int, name: String?, plainName: String, encryptVersion: String = "03-aes" , folderUuid: String? = nil) {
        self.fileId = fileId
        self.type = type
        self.bucket = bucket
        self.size = size
        self.folder_id = folderId
        self.folderUuid = folderUuid
        self.name = name
        self.plain_name = plainName
        self.encrypt_version = encryptVersion
    }
    
    enum CodingKeys: String, CodingKey {
        case fileId
        case type
        case bucket
        case size
        case folder_id
        case folderUuid
        case name
        case plain_name = "plainName"
        case encrypt_version = "encryptVersion"
    }
}

public struct CreateFilePayload: Encodable {
    public let file: CreateFileData
}

public struct CreateThumbnailData: Encodable {
    public let bucket_file: String
    public let bucket_id: String
    public let encrypt_version = "03-aes"
    public let file_id: Int?
    public let max_height: Int
    public let max_width: Int
    public let size: Int64
    public let type: String
    public let fileUuid: String
    
    public init(bucketFile: String, bucketId: String,fileId: Int? = nil, height: Int, width: Int, size: Int64, type: String,fileUuid: String) {
        self.bucket_file = bucketFile
        self.bucket_id = bucketId
        self.file_id = fileId
        self.max_height = height
        self.max_width = width
        self.size = size
        self.type = type
        self.fileUuid = fileUuid
    }
    
    enum CodingKeys: String, CodingKey {
        case bucket_file = "bucketFile"
        case bucket_id = "bucketId"
        case encrypt_version = "encryptVersion"
        case file_id = "fileId"
        case max_height = "maxHeight"
        case max_width = "maxWidth"
        case size
        case type
        case fileUuid
    }
}

public struct CreateThumbnailDataOld: Encodable {
    public let bucket_file: String
    public let bucket_id: String
    public let encrypt_version = "03-aes"
    public let file_id: Int
    public let max_height: Int
    public let max_width: Int
    public let size: Int64
    public let type: String
    
    public init(bucketFile: String, bucketId: String, fileId: Int, height: Int, width: Int, size: Int64, type: String) {
        self.bucket_file = bucketFile
        self.bucket_id = bucketId
        self.file_id = fileId
        self.max_height = height
        self.max_width = width
        self.size = size
        self.type = type
    }
}


public struct CreateThumbnailPayload: Encodable {
    public let thumbnail: CreateThumbnailData
}

public struct CreateThumbnailPayloadOld: Encodable {
    public let thumbnail: CreateThumbnailDataOld
}

public struct CreateThumbnailResponse: Decodable {
    public let fileId: Int
}

public struct CreateFileResponse: Decodable {
    public let created_at: String
    public let deleted: Bool?
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

public struct CreateFileResponseNew: Decodable {
    public let deleted: Bool?
    public let status: String
    public let id: Int
    public let name: String?
    public let plain_name: String
    public let type: String?
    public let size: String?
    public let folderId: Int
    public let fileId: String?
    public let bucket: String
    public let encrypt_version: String
    public let userId: Int
    public let modificationTime: String
    public let updatedAt: String
    public let createdAt: String
    public let deletedAt: String?
    public let uuid: String
    public let folderUuid: String?
    
  
    enum CodingKeys: String, CodingKey {
        case deleted
        case status
        case id
        case name
        case plain_name = "plainName"
        case type
        case size
        case folderId
        case fileId
        case bucket
        case encrypt_version = "encryptVersion"
        case userId
        case modificationTime
        case updatedAt
        case createdAt
        case deletedAt
        case uuid
        case folderUuid
    }
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
    public let token: String?
    public let user: DriveUser
    public let newToken: String
}

public struct RefreshTokensResponse: Decodable {
    public let token: String
    public let newToken: String
}

public struct PushDeviceTokenPayload: Encodable {
    public let token: String
    public let type: String
}

public struct PushDeviceTokenResponse: Decodable {}



public struct MoveFilePayload: Encodable {
    public let bucketId: String
    public let destination: Int
    public let fileId: String
    public let relativePath:String = NSUUID().uuidString
}

public struct MoveFilePayloadNew: Encodable {
    public let destinationFolder: String
}


public struct MoveFileResponse: Decodable {
    public let moved: Bool
}

public struct MoveFileResponseNew: Decodable {
    public let type: String?
    public let size: String
}


public struct DeleteFolderResponse: Decodable {}


public struct MoveFolderPayload: Encodable {
    public let folderId: Int
    public let destination: Int
}


public struct MoveFolderResponse: Decodable {
    public let moved: Bool
}

public struct MoveFolderResponseNew: Decodable {}


public struct GetLimitResponse: Decodable {
    public let maxSpaceBytes: Int64
}


public struct GetDriveUsageResponse: Decodable {
    public let drive: Int64
    public let backups: Int64?
}


public struct UpdatedFile: Decodable {
    public let id: Int;
    public let uuid: String;
    public let folderId: Int;
    public let status: String;
    public let size: String;
    public let name: String;
    public let plainName: String?
    public let updatedAt: String
    public let createdAt: String
    public let type: String?
    public let folderUuid: String?
}


public typealias GetUpdatedFilesResponse = [UpdatedFile]


public struct UpdatedFolder: Decodable {
    public let id: Int;
    public let parentId: Int?;
    public let status: String;
    public let name: String;
    public let plainName: String?
    public let updatedAt: String
    public let createdAt: String
    public let parentUuid: String?
    public let uuid: String?
}

public typealias GetUpdatedFoldersResponse = [UpdatedFolder]


public struct ReplaceFileIdPayload: Encodable {
    public let fileId: String?
    public let size: Int
}


public struct ReplaceFileResponse: Decodable {
    public let uuid: String
    public let fileId: String?
    public let size: Int
}


public struct GetFileInFolderByPlainNameResponse: Decodable {
    public let id: Int
    public let uuid: String
    public let fileId: String?
    public let name: String?
    public let type: String?
}


public struct GetDriveItemMetaByIdResponse: Decodable {
    public let id: Int
    public let parentId: Int?
    public let name: String
    public let bucket: String?
    public let userId: Int
    public let encryptVersion: String?
    public let deleted: Bool?
    public let createdAt: String
    public let updatedAt: String
    public let deletedAt: String?
    public let removedAt: String?
    public let uuid: String?
    public let plainName: String?
    public let removed: Bool?
    public let folderId: Int?
    public let type: String?
    public let size: String?
    public let fileId: String?
    public let modificationTime: String?
    public let status: String?
    
    public var isFolder: Bool {
        return type == "folder"
    }
    
}


public struct GetAvailableWorkspacesResponse: Codable {
    public let availableWorkspaces: [AvailableWorkspace]
    public let pendingWorkspaces: [PendingWorkspace]
}


public struct AvailableWorkspace: Codable {
    public let workspaceUser: WorkspaceUser
    public let workspace: Workspace
}


public struct WorkspaceUser: Codable {
    public let id: String
    public let memberId: String
    public let key: String
    public let workspaceId: String
    public let rootFolderId: String
    public let spaceLimit: Int64
    public let driveUsage: Int64
    public let backupsUsage: Int64
    public let deactivated: Bool
    public let member: String?
    public let createdAt: String
    public let updatedAt: String
}


public struct Workspace: Codable {
    public let id: String
    public let ownerId: String
    public let address: String
    public let name: String
    public let avatar: String?
    public let description: String
    public let defaultTeamId: String
    public let workspaceUserId: String
    public let setupCompleted: Bool
    public let rootFolderId: String
    public let numberOfSeats: Int
    public let phoneNumber: String?
    public let createdAt: String
    public let updatedAt: String
}

public struct PendingWorkspace: Codable {
}

public struct CreateFolderWorkspacePayload: Encodable {
    public let parentFolderUuid: String
    public let name: String
    init(parentFolderUuid: String, folderName: String)  {
        self.parentFolderUuid = parentFolderUuid
        self.name = folderName
    }
}

public struct WorkspaceCredentialsResponse: Codable {
    public let workspaceId: String
    public let bucket: String
    public let workspaceUserId: String
    public let email: String
    public let credentials: Credentials
    public let tokenHeader: String
}

public struct Credentials: Codable {
    public let networkPass: String
    public let networkUser: String
}

public struct ExistenceFilePayload: Encodable {
    public let files: Array<ExistenceFile>
    
    public init(files: Array<ExistenceFile>) {
        self.files = files
    }
}

public struct ExistenceFile: Encodable {
    public let plainName: String
    public let type: String
    
    public init(plainName: String, type: String)  {
        self.plainName = plainName
        self.type = type
    }
}


public struct ExistenceFilesResponse: Codable {
    public let existentFiles: Array<GetExistenceFileInFolderResponse>
}

public struct GetExistenceFileInFolderResponse: Codable {
    public let id: Int
    public let uuid: String
    public let fileId: String?
    public let name: String?
    public let type: String?
    public let plainName: String
}

public struct GetPaymentInfoResponse: Decodable {
    public let featuresPerService : FeaturesPerServiceNew
}

public struct FeaturesPerService: Codable {
    public let antivirus: Bool
    public let backups: Bool?
}

public struct LogoutResponse: Decodable {
    public let logout : Bool
}


public struct ExistentFoldersResponse: Decodable {
    public let existentFolders: [FolderResponse]
}

public struct FolderResponse: Decodable {
    public let type: String
    public let id: Int
    public let parentId: Int?
    public let parentUuid: String?
    public let name: String
    public let encryptVersion: String
    public let createdAt: String
    public let updatedAt: String
    public let uuid: String
    public let plainName: String
    public let size: Int
    public let removed: Bool
    public let status: String
}

public struct PlainNamesPayload: Encodable {
    public let plainNames: Array<String>
    
    public init(plainNames: Array<String>) {
        self.plainNames = plainNames
    }
}

public struct FeaturesPerServiceNew: Codable {
    public let antivirus: Bool
    public let backups: Bool?
    public let cleaner: Bool?
    
    private struct FeatureDetail: Codable {
        let enabled: Bool
    }
    
    private enum CodingKeys: String, CodingKey {
        case antivirus, backups, cleaner
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let antivirusDetail = try container.decode(FeatureDetail.self, forKey: .antivirus)
        self.antivirus = antivirusDetail.enabled
        
        let backupsDetail = try? container.decodeIfPresent(FeatureDetail.self, forKey: .backups)
        self.backups = backupsDetail?.enabled
        
        let cleanerDetail = try? container.decodeIfPresent(FeatureDetail.self, forKey: .cleaner)
        self.cleaner = cleanerDetail?.enabled
    }
}


public struct GetNotificationsResponse: Codable {
    public let id: String
    public let link: String
    public let message: String
    public let expiresAt: String?
    public let createdAt: String
    public let deliveredAt: String
    public let readAt: String
    public let isRead: Bool
}
