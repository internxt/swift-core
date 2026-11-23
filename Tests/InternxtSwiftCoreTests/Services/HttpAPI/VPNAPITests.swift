//
//  VPNAPITests.swift
//  InternxtSwiftCoreTests
//
//  Created by Xavier Abad Gomez on 23/11/2026.
//

import XCTest
@testable import InternxtSwiftCore

final class VPNAPITests: XCTestCase {

    private var api: VPNAPI!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        api = VPNAPI(
            baseUrl: "https://vpn.test",
            authToken: "user-token",
            urlSession: URLSession(configuration: configuration),
            clientName: "drive-desktop",
            clientVersion: "2.8.0"
        )
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        api = nil
        super.tearDown()
    }

    func testWhenTheUserIsLoggedInThenTheirVPNZonesAreReturned() async throws {
        var receivedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            receivedRequest = request
            let body = """
            {"uuid":"user-uuid","zones":["FR","DE","PL"],"createdAt":"2026-01-01T00:00:00.000Z","updatedAt":"2026-01-01T00:00:00.000Z"}
            """
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data(body.utf8))
        }

        let user = try await api.getUser()

        XCTAssertEqual(user.zones, [.france, .germany, .poland])
        XCTAssertEqual(receivedRequest?.url?.absoluteString, "https://vpn.test/users")
        XCTAssertEqual(receivedRequest?.httpMethod, "GET")
        XCTAssertEqual(receivedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer user-token")
    }

    func testWhenTheBackendOffersARegionThisVersionDoesNotKnowThenTheKnownZonesAreStillReturned() async throws {
        MockURLProtocol.requestHandler = { request in
            let body = #"{"uuid":"user-uuid","zones":["FR","US","UK"]}"#
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data(body.utf8))
        }

        let user = try await api.getUser()

        XCTAssertEqual(user.zones, [.france, .unitedKingdom])
    }

    func testWhenTheSessionHasExpiredThenFetchingTheZonesFailsAsUnauthorized() async {
        MockURLProtocol.requestHandler = { request in
            let body = #"{"message":"Unauthorized","statusCode":401}"#
            return (HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!, Data(body.utf8))
        }

        do {
            _ = try await api.getUser()
            XCTFail("Expected an unauthorized error")
        } catch let error as APIClientError {
            XCTAssertEqual(error.statusCode, 401)
        } catch {
            XCTFail("Expected an APIClientError, got \(error)")
        }
    }
}
