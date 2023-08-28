//
//  KeyDerivationTests.swift
//  InternxtSwiftCoreTests
//
//  Created by Robert Garcia on 31/7/23.
//

import XCTest
@testable import InternxtSwiftCore

final class KeyDerivationTests: XCTestCase {

    let sut = KeyDerivation()
    let utils = CryptoUtils()

    func testPbkdf2() throws {
        let password = String("testpassword")
        let salt = String("testsalt")
        let rounds = 2048
        let derivedKeyLength = 64
        let result = sut.pbkdf2(password: password, salt: salt, rounds: rounds, derivedKeyLength: derivedKeyLength)
        
        XCTAssertEqual(utils.bytesToHexString(result), "23c999c8753e1deec3aa8638cd4407f241b0184ad35f7b71be9af5266e6ad31c8025a88e1fe92a03a3815fa35d1b823294f6b4ba79619d52b911f215fe56ae24")
        
    }
    
    func testPbkdf2InputPassword() throws {
        let password = String("password")
        let salt = String("salt")
        let rounds = 1
        let derivedKeyLength = 20
        let result = sut.pbkdf2(password: password, salt: salt, rounds: rounds, derivedKeyLength: derivedKeyLength)
        
        XCTAssertEqual(utils.bytesToHexString(result), "867f70cf1ade02cff3752599a3a53dc4af34c7a6")
        
    }
    
    func testPbkdf2InputPasswordPASSWORDpassword() throws {
        let password = String("passwordPASSWORDpassword")
        let salt = String("saltSALTsaltSALTsaltSALTsaltSALTsalt")
        let rounds = 4096
        let derivedKeyLength = 25
        let result = sut.pbkdf2(password: password, salt: salt, rounds: rounds, derivedKeyLength: derivedKeyLength)
        
        XCTAssertEqual(utils.bytesToHexString(result), "8c0511f4c6e597c6ac6315d8f0362e225f3c501495ba23b868")
        
    }
    
    func testPbkdf2WithSaltBytes() throws {
        let password = "password123"
        let saltBytes: [UInt8] = [56, 220, 224, 57, 27, 73, 239, 186, 136, 219, 200, 195, 158, 191, 134, 143, 2, 103, 235, 17, 11, 176, 1, 42, 178, 125, 197, 42, 82, 141, 97, 177, 209, 237, 157, 118, 244, 0, 255, 88, 227, 36, 0, 40, 68, 43, 30, 171, 155, 184, 78, 17, 29, 157, 173, 217, 151, 152, 45, 189, 233, 219, 210, 94]
        let rounds = 2145
        let derivedKeyLength = 32
        let result = sut.pbkdf2(password: password, salt: saltBytes, rounds: rounds, derivedKeyLength: derivedKeyLength)
        
        XCTAssertEqual(utils.bytesToHexString(result), "0ae7fc4587bbec27d6eb8c471eafdf35c7cbb37f0fe2f8535d67ca3114801e8c")
        
    }

}
