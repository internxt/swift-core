//
//  CryptoUtilsTests.swift
//  InternxtSwiftCoreTests
//
//  Created by Robert Garcia on 4/8/23.
//

import XCTest
@testable import InternxtSwiftCore
final class CryptoUtilsTests: XCTestCase {
    let sut = CryptoUtils()
    
    func testGenerateDeterministicKeyCorrectly() throws {
        
        let result = sut.getDeterministicKey(key: Array("imthekey".utf8), data: Array("imthedata".utf8))

        XCTAssertEqual(sut.bytesToHexString(result), "cfd67e51df9354be8fbc8a3552674f1a2ed2ec8dd7ba2d93621a2ff3ee4862bffdc7d921469232ac4f00c0d605f7379e2b343466413e79f4bdaef3d2713fe525")
    }
    
    func testShouldFailIfBucketIdIsNotValidHex() throws {
        XCTAssertThrowsError(try sut.generateBucketKey(mnemonic: "mnemonic", bucketId: "wronghex"))
    }
   
    func testShouldGenerateBucketKeyCorrectly() throws {
        let expected = "2afacb1df30708c6c705c7acb0222c6db803086b3b47c65ca2785ba36a07399f8a28d645084ce87a64eeaec25fdcebf07236f02a9de38df3729b4ee57caa9428"
        let mnemonic = "essence renew fish any airport nature tape gallery tobacco inside there enlist hub bring meat wing crack review logic open husband excite bag reflect"
        let bucketId = "e8f6c43b49d72e21aa6094f0"
        let result = try sut.generateBucketKey(mnemonic: mnemonic, bucketId: bucketId)
        
        XCTAssertEqual(expected, sut.bytesToHexString(result))
        
    }

}
