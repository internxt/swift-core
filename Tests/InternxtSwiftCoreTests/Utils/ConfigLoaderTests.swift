//
//  ConfigLoaderTests.swift
//  InternxtSwiftCoreTests
//
//  Created by Robert Garcia on 1/8/23.
//

import XCTest
@testable import InternxtSwiftCore


final class ConfigLoaderTests: XCTestCase {

    let sut = ConfigLoader()

    func testMustSetAConfig() throws {
        XCTAssertThrowsError(try sut.getConfigProperty(configKey: "Hello"))
    }
    
    func testShouldReturnAConfigValueOnceLoaded() throws {
        sut.load(config: Config(
            DRIVE_URL: "drive_url", NETWORK_URL: "network_url"
        ))
        let value =  try sut.getConfigProperty(configKey: "DRIVE_URL")
        
        XCTAssertEqual(value, "drive_url")
    }
}
