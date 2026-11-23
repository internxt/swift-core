//
//  PaymentInfoDecodingTests.swift
//  InternxtSwiftCoreTests
//
//  Created by Xavier Abad Gomez on 23/11/2026.
//

import XCTest
@testable import InternxtSwiftCore

final class PaymentInfoDecodingTests: XCTestCase {

    func testWhenThePlanIncludesVPNThenVPNIsReportedAsEnabled() throws {
        let body = """
        {"featuresPerService":{"antivirus":{"enabled":true},"mail":{"enabled":true},"vpn":{"enabled":true,"featureId":"vpn-tier-3"}}}
        """

        let paymentInfo = try JSONDecoder().decode(GetPaymentInfoResponse.self, from: Data(body.utf8))

        XCTAssertEqual(paymentInfo.featuresPerService.vpn, true)
    }

    func testWhenThePlanExcludesVPNThenVPNIsReportedAsDisabled() throws {
        let body = """
        {"featuresPerService":{"antivirus":{"enabled":true},"vpn":{"enabled":false,"featureId":"vpn-free"}}}
        """

        let paymentInfo = try JSONDecoder().decode(GetPaymentInfoResponse.self, from: Data(body.utf8))

        XCTAssertEqual(paymentInfo.featuresPerService.vpn, false)
    }

    func testWhenThePlanDoesNotMentionVPNThenVPNIsUnknownAndTheOtherFeaturesStillDecode() throws {
        let body = """
        {"featuresPerService":{"antivirus":{"enabled":true},"backups":{"enabled":false},"cleaner":{"enabled":true},"mail":{"enabled":true}}}
        """

        let paymentInfo = try JSONDecoder().decode(GetPaymentInfoResponse.self, from: Data(body.utf8))

        XCTAssertNil(paymentInfo.featuresPerService.vpn)
        XCTAssertEqual(paymentInfo.featuresPerService.antivirus, true)
        XCTAssertEqual(paymentInfo.featuresPerService.backups, false)
        XCTAssertEqual(paymentInfo.featuresPerService.cleaner, true)
        XCTAssertEqual(paymentInfo.featuresPerService.mail, true)
    }
}
