//
//  NetworkTypes.swift
//  
//
//  Created by Robert Garcia on 4/8/23.
//

import Foundation

public struct NetworkUploadPayload: Codable {
    public let index: Int
    public let size: Int
}

public struct StartUploadPayload: Codable {
    public let uploads: Array<NetworkUploadPayload>
}


public struct StartUploadResult: Decodable {
    public let uuid: String
    public let url: String?
    public let urls: Array<String>?
    public let UploadId: String?
}
public struct StartUploadResponse: Decodable {
    public let uploads: Array<StartUploadResult>
}

public struct ShardPartPayload: Codable {
    public let ETag: String
    public let PartNumber: Int
}

public struct ShardUploadPayload: Codable {
    public let hash: String
    public let uuid: String
    public let parts: [ShardPartPayload]?
    public let UploadId: String?
    init(hash: String, uuid: String, parts: [ShardPartPayload]? = nil, uploadId: String? = nil) {
        self.hash = hash
        self.uuid = uuid
        self.parts = parts
        self.UploadId = uploadId
    }
}


public struct FinishUploadPayload: Codable {
    public let index: String
    public let shards: Array<ShardUploadPayload>
    
    public init(index: String, shards: Array<ShardUploadPayload>) throws {
       
        self.index = index
        self.shards = shards
    }
}


public struct FinishUploadResponse: Decodable {
    public let bucket: String
    public let index: String
    public let size: Int
    public let version: Int
    // ISO Date
    public let created: String
    // ISO Date
    public let renewal: String
    public let mimetype: String
    public let filename: String
    public let id: String
}

public struct GetFileInfoShard: Decodable {
    public let index: Int
    public let hash: String
    public let url: String
}

public struct GetFileInfoResponse: Decodable {
    public let bucket: String
    public let index: String
    public let size: Int
    public let version: Int
    // ISO Date
    public let created: String
    // ISO Date
    public let renewal: String
    public let mimetype: String
    public let filename: String
    public let id: String
    public let shards: Array<GetFileInfoShard>?
}


public struct FileMirrorShard: Decodable {
  public let index: Int
  public let hash: String
  public let size: Int
  public let url: String
}
