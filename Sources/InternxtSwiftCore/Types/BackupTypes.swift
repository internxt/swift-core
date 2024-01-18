//
//  BackupTypes.swift
//  
//
//  Created by Richard Ascanio on 1/18/24.
//

import Foundation

public struct GetAllDevicesResponse: Codable {
    public let devices: Array<Device>
}

public struct Device: Codable {
    public let id: String
    public let mac: String?
    public let name: String?
    public let userId: String?
    public let newestDate: String?
    public let oldestDate: String?
    public let createdAt: String
    public let updatedAt: String
}
