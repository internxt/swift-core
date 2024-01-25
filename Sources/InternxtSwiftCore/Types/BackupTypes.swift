//
//  BackupTypes.swift
//  
//
//  Created by Richard Ascanio on 1/18/24.
//

import Foundation

public typealias DevicesResponse = [Device]

public struct Device: Codable {
    public let id: String
    public let uuid: String
    public let parentId: String?
    public let parentUuid: String?
    public let name: String?
    public let plain_name: String?
    public let bucket: String?
    public let user_id: String?
    public let encrypt_version: String?
    public let deleted: Bool
    public let deletedAt: String?
    public let removed: Bool
    public let removedAt: String?
    public let createdAt: String
    public let updatedAt: String
    public let userId: String?
    public let parent_id: String?
}
