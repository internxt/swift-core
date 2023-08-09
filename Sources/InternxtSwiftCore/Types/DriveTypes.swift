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
}

public struct GetFolderFilesResponse: Decodable {
    public let result: Array<GetFolderFilesResult>
}



public struct GetFolderFoldersResult: Decodable {
    public let type: String
    public let id: Int
    public let parentId: Int
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

public struct MetadataUpdatePayload: Encodable {
    public let itemName: String
}


public struct UpdateFolderPayload: Encodable {
    public let metadata: MetadataUpdatePayload
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
   
}
