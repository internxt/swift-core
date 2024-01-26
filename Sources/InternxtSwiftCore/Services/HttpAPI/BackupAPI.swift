//
//  BackupAPI.swift
//  
//
//  Created by Richard Ascanio on 1/18/24.
//

import Foundation

@available(macOS 10.15, *)
public struct BackupAPI {
    private let baseUrl: String
    private let apiClient: APIClient

    public init(baseUrl: String, authToken: String, clientName: String, clientVersion: String) {
        self.baseUrl = baseUrl
        self.apiClient = APIClient(urlSession: URLSession.shared, authorizationHeaderValue: "Bearer \(authToken)", clientName: clientName, clientVersion: clientVersion)
    }

    public func getAllDevices(debug: Bool = false) async throws -> DevicesResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/backup/deviceAsFolder",
            method: .GET
        )

        return try await apiClient.fetch(type: DevicesResponse.self, endpoint, debugResponse: debug)
    }

    public func addDeviceAsFolder(deviceName: String, debug: Bool = false) async throws -> Device {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/backup/deviceAsFolder",
            method: .POST,
            body: CreateDevicePayload(deviceName: deviceName).toJson()
        )

        return try await apiClient.fetch(type: Device.self, endpoint, debugResponse: debug)
    }
}
