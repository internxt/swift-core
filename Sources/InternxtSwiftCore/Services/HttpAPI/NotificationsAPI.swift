//
//  File.swift
//  InternxtSwiftCore
//
//  Created by Patricio Tovar on 10/10/25.
//

import Foundation

@available(macOS 10.15, *)
public struct NotificationsAPI {
    private let baseUrl: String
    private let apiClient: APIClient
    private let clientName: String
    private let clientVersion: String
    public init(baseUrl: String, authToken: String, clientName: String, clientVersion: String, gatewayHeader: String? = nil) {
        self.baseUrl = baseUrl
        self.apiClient = APIClient(urlSession: APIClient.ephemeralSession, authorizationHeaderValue: "Bearer \(authToken)", clientName: clientName,
                                   clientVersion: clientVersion,
                                   authorizationHeaderGatewayValue: gatewayHeader
        )
        self.clientName = clientName
        self.clientVersion = clientVersion
    }
    
    
    public func getNotifications(debug: Bool = false) async throws -> [GetNotificationsResponse] {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/notifications",
            method: .GET
        )
        
        return try await apiClient.fetch(type: [GetNotificationsResponse].self, endpoint, debugResponse: debug)
    }
    
}
