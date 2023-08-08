//
//  DriveTypes.swift
//  
//
//  Created by Robert Garcia on 6/8/23.
//

import Foundation


struct GetFolderFilesEndpoint: Endpoint {
    var body: Data? = nil
    let method =  HTTPMethod.GET
    let path: String
    init(path: String) {
        self.path = path
    }
}

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
    public let removed: Bool?
    // ISO string
    public let removedAt: String
    public let status: String
}

public struct GetFolderFilesResponse: Decodable {
    public let result: Array<GetFolderFilesResult>
}

struct GetFolderFoldersEndpoint: Endpoint {
    var body: Data? = nil
    let method =  HTTPMethod.GET
    let path: String
    init(path: String) {
        self.path = path
    }
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
    public let createdAt: String?
    // ISO string
    public let updatedAt: String?
    public let plainName: String?
    public let removed: Bool
    // ISO string
    public let removedAt: String?
}

public struct GetFolderFoldersResponse: Decodable {
    public let result: Array<GetFolderFoldersResult>
}


struct CreateFolderEndpoint: Endpoint {
    var body: Data?
    let method: HTTPMethod =  HTTPMethod.POST
    let path: String
    init(path: String, body: Data?) {
        self.path = path
        self.body = body
    }
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


struct UpdateFolderEndpoint: Endpoint {
    var body: Data?
    let method: HTTPMethod =  HTTPMethod.POST
    let path: String
    init(path: String, body: Data?) {
        self.path = path
        self.body = body
    }
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


struct TrashFolderEndpoint: Endpoint {
    var body: Data?
    let method: HTTPMethod =  HTTPMethod.POST
    let path: String
    init(path: String, body: Data?) {
        self.path = path
        self.body = body
    }
}
