//
//  MailAPI.swift
//  InternxtSwiftCore
//
//  Created by Xavier Abad Gomez on 11/09/2026.
//

import Foundation

@available(macOS 10.15, *)
public struct MailAPI {
    private let baseUrl: String
    private let apiClient: APIClient
    private let clientName: String
    private let clientVersion: String

    public init(baseUrl: String, authToken: String, clientName: String, clientVersion: String, workspaceHeader: String? = nil, gatewayHeader: String? = nil) {
        self.baseUrl = baseUrl
        self.apiClient = APIClient(urlSession: APIClient.ephemeralSession, authorizationHeaderValue: "Bearer \(authToken)", clientName: clientName,
                                   clientVersion: clientVersion,
                                   workspaceHeader: workspaceHeader,
                                   authorizationHeaderGatewayValue: gatewayHeader
        )
        self.clientName = clientName
        self.clientVersion = clientVersion
    }

    /// The account's mail address and encryption keys.
    public func getMailAccountKeys(debug: Bool = false) async throws -> MailAccountKeysResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/users/me/mail-account/keys",
            method: .GET
        )

        return try await apiClient.fetch(type: MailAccountKeysResponse.self, endpoint, debugResponse: debug)
    }
}
