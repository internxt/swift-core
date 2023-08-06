//
//  DriveTypes.swift
//  
//
//  Created by Robert Garcia on 6/8/23.
//

import Foundation


public struct FolderChild: Decodable {
    // ISO string
    let createdAt: String
    let encrypt_version: String
    let id: Int
    let name: String
    let plain_name: String?
    let parentId: Int
    let parent_id: Int
    let updatedAt: String
    let userId: Int
    let user_id: Int
}

public struct DriveFileData: Decodable {
    let bucket: String
    // ISO string
    let createdAt: String
    let created_at: String
    let deleted: Bool
    let encrypt_version: String
    let fileId: String
    let folderId: Int
    let folder_id: Int
    let id: Int
    let name: Int
    let plain_name: String?
    let size: Int
    let type: String
    // ISO string
    let updatedAt: String
}

public struct FetchFolderContentResponse: Decodable {
    let bucket: String?
    let children: Array<FolderChild>
    let files: Array<DriveFileData>
    // ISO string
    let createdAt: String
    let encrypt_version: String
    let id: Int
    let name: String
    let plain_name: String?
    let parentId: Int?
    let parent_id: Int?
    // ISO string
    let updatedAt: String
    let userId: Int
    let user_id: Int
}
