//
//  DriveTypes.swift
//  
//
//  Created by Robert Garcia on 6/8/23.
//

import Foundation


public struct FolderChild: Decodable {
    // ISO string
    public let createdAt: String
    public let encrypt_version: String?
    public let id: Int
    public let name: String
    public let plain_name: String?
    public let parentId: Int
    public let parent_id: Int
    public let updatedAt: String
    public let userId: Int
    public let user_id: Int
}

public struct DriveFileData: Decodable {
    public let bucket: String
    // ISO string
    public let createdAt: String
    public let created_at: String
    public let deleted: Bool
    public let encrypt_version: String?
    public let fileId: String
    public let folderId: Int
    public let folder_id: Int
    public let id: Int
    public let name: Int
    public let plain_name: String?
    public let size: Int
    public let type: String
    // ISO string
    public let updatedAt: String
}

public struct FetchFolderContentResponse: Decodable {
    public let bucket: String?
    public let children: Array<FolderChild>
    public let files: Array<DriveFileData>
    // ISO string
    public let createdAt: String
    public let encrypt_version: String?
    public let id: Int
    public let name: String
    public let plain_name: String?
    public let parentId: Int?
    public let parent_id: Int?
    // ISO string
    public let updatedAt: String
    public let userId: Int
    public let user_id: Int
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
    public let bucket: String
    public let id: Int
    public let name: String
    public let plain_name: String?
    public let parentId: Int?
    // ISO Date
    public let createdAt: String
    public let updatedAt: String
    public let userId: Int
}
