//
//  VPNTypes.swift
//  InternxtSwiftCore
//
//  Created by Xavier Abad Gomez on 23/11/2026.
//

import Foundation

public enum VPNZone: String, CaseIterable {
    case france = "FR"
    case germany = "DE"
    case poland = "PL"
    case canada = "CA"
    case unitedKingdom = "UK"
}

public struct VPNUserResponse: Decodable {
    public let zones: [VPNZone]

    private enum CodingKeys: String, CodingKey {
        case zones
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawZones = try container.decode([String].self, forKey: .zones)
        self.zones = rawZones.compactMap(VPNZone.init(rawValue:))
    }
}
