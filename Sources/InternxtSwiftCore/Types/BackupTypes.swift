//
//  BackupTypes.swift
//  
//
//  Created by Richard Ascanio on 1/18/24.
//

import Foundation

public typealias DevicesResponse = [DeviceAsFolder]

public struct DeviceAsFolder: Codable, Identifiable {
    public let id: Int
    public let uuid: String
    public let parentId: String?
    public let parentUuid: String?
    public let name: String?
    public let plain_name: String?
    public let bucket: String?
    public let user_id: Int?
    public let encrypt_version: String?
    public let deleted: Bool
    public let deletedAt: String?
    public let removed: Bool
    public let removedAt: String?
    public let createdAt: String
    public let updatedAt: String
    public let userId: Int?
    public let parent_id: String?
    public var hasBackups: Bool? = false
    public let lastBackupAt: String?
}

public struct CreateDevicePayload: Encodable {
    public let deviceName: String
}
