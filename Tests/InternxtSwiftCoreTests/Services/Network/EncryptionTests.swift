//
//  EncryptionTests.swift
//  InternxtSwiftCoreTests
//
//  Created by Robert Garcia on 7/8/23.
//

import XCTest
@testable import InternxtSwiftCore

final class EncryptionTests: XCTestCase {
    let sut = Encrypt()
    let cryptoUtils = CryptoUtils()

    func testGenerateFileKeyShouldFailIfNotCorrectLength() throws {
        let mnemonic = "essence renew fish any airport nature tape gallery tobacco inside there enlist hub bring meat wing crack review logic open husband excite bag reflect"
        
        let bucketId = "e8f6c43b49d72e21aa6094f0"
        // 33 bytes
        let indexHex = "fa709a1bffc713d0762accf883ec01a7410281213ca936fbe7455d9bd0c8e6acf9"
        XCTAssertThrowsError(try sut.generateFileKey(mnemonic: mnemonic, bucketId: bucketId, index: cryptoUtils.hexStringToBytes(indexHex)))
    }
    
    func testGenerateFileKeyCorrectly() throws {
        let mnemonic = "genre ticket elbow melt typical reduce violin blue feed fashion elephant chuckle pyramid father lab patrol acoustic flower disorder artist coast door dynamic avoid"
        
        let bucketId = "7ea7af63584b62938645ec55"
        
        let indexHex = "7ff620785efea0c819e8f9746aa11db00c14ac32a2a48359bcbcc4af4b158c08"
        let expected = "8bf2177e82d9c5f6e21ec8f2d660dee5b92df7e17a0208d1f301f34929ca7609"
        let result = try sut.generateFileKey(mnemonic: mnemonic, bucketId: bucketId, index: cryptoUtils.hexStringToBytes(indexHex))
        
        XCTAssertEqual(cryptoUtils.bytesToHexString(result), expected)
    
    }

}
