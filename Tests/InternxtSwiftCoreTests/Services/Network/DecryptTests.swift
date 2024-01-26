//
//  Decrypt.swift
//  InternxtSwiftCoreTests
//
//  Created by Robert Garcia on 26/1/24.
//

import XCTest
@testable import InternxtSwiftCore

final class DecryptTests: XCTestCase {
    let sut = Decrypt()
    let cryptoUtils = CryptoUtils()

    

    func testDecryptStringCorrectly() throws {
        let expectedResult = "encryptthistext"
        let base64String = "ONzgORtJ77qI28jDnr+GjwJn6xELsAEqsn3FKlKNYbHR7Z129AD/WOMkAChEKx6rm7hOER2drdmXmC296dvSXtE5y5os0XCS554YYc+dcCOL3K8m3lqzQeazS5SkAzquf98NCcKSKe7a6sfSYtoS"
        
        let result = try sut.decrypt(base64String: base64String, password: "password123")
    
        
        XCTAssertEqual(result, expectedResult)
    }
    
    func testDecryptStringCorrectly2() throws {
        
        let base64String = "RTlOyTqd2mq+s0psxsvNYUpRvcQuntYD7gh2mLucE6rmL6l0prihaywSFQ3lb1hMBowott0A7plvtkmREBxhlSJCnhxrWe8GdR+bLJ0qruEpN9n67xeuMUB/myfxTPIY7z++/U0yxlR2+1RiFC9dwFVc"
        
        let result = try sut.decrypt(base64String: base64String ,password: "passwordPASS123!lokqfqwf", rounds: 2000)

        let expectedResult = "textTEXTtext123123"
        
        XCTAssertEqual(result, expectedResult)
    }

    

}
