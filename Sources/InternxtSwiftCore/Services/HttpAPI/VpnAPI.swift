//
//  VPNAPI.swift
//  InternxtSwiftCore
//
//  Created by Xavier Abad Gomez on 23/11/2026.
//

import Foundation

@available(macOS 10.15, *)
public struct VPNAPI {
    private let baseUrl: String
    private let apiClient: APIClient

    public init(baseUrl: String, authToken: String, urlSession: URLSession? = nil, clientName: String, clientVersion: String) {
        self.baseUrl = baseUrl
        self.apiClient = APIClient(
            urlSession: urlSession ?? APIClient.ephemeralSession,
            authorizationHeaderValue: "Bearer \(authToken)",
            clientName: clientName,
            clientVersion: clientVersion
        )
    }

    /// The VPN regions the user's plan gives access to.
    public func getUser(debug: Bool = false) async throws -> VPNUserResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/users",
            method: .GET
        )

        return try await apiClient.fetch(type: VPNUserResponse.self, endpoint, debugResponse: debug)
    }
}
