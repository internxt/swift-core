//
//  EncryptionTests.swift
//  InternxtSwiftCoreTests
//
//  Created by Robert Garcia on 7/8/23.
//

import XCTest
@testable import InternxtSwiftCore

final class EncryptTests: XCTestCase {
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
    
    
    func testGetFileContentHashCorrectly() throws {
        let source = InputStream(data: Data("imTheContentOfThisFile".utf8))
        let expectedValue = "4eef3af75813f505b9050f575b8d2e782c9db5d7"
        let result = sut.getFileContentHash(stream: source)
        
        XCTAssertEqual(cryptoUtils.bytesToHexString(Array(result)), expectedValue)
    }
    
    func testEncryptStringCorrectly() throws {
        let ivHex = "d139cb9a2cd17092e79e1861cf9d7023"
        let saltHex = "38dce0391b49efba88dbc8c39ebf868f0267eb110bb0012ab27dc52a528d61b1d1ed9d76f400ff58e3240028442b1eab9bb84e111d9dadd997982dbde9dbd25e"
        let expectedBase64 = "ONzgORtJ77qI28jDnr+GjwJn6xELsAEqsn3FKlKNYbHR7Z129AD/WOMkAChEKx6rm7hOER2drdmXmC296dvSXtE5y5os0XCS554YYc+dcCOL3K8m3lqzQeazS5SkAzquf98NCcKSKe7a6sfSYtoS"
        
        let result = try sut.encrypt(string: "encryptthistext", password: "password123", salt: cryptoUtils.hexStringToBytes(saltHex), iv: Data(cryptoUtils.hexStringToBytes(ivHex)))
        
        XCTAssertEqual(result.base64EncodedString(), expectedBase64)
    }
}
