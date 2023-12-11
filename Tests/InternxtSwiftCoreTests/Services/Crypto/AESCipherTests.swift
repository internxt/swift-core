//
//  AESCipherTests.swift
//  InternxtSwiftCoreTests
//
//  Created by Robert Garcia on 31/7/23.
//

import XCTest
@testable import InternxtSwiftCore
import IDZSwiftCommonCrypto
final class AESCipherTests: XCTestCase {

    let sut = AESCipher()
    let utils = CryptoUtils()
    
    func getTemporaryURL() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory() + "/test_\(UUID())")
    }
    
    
    func testEncryptStream() throws {
        let destination = getTemporaryURL()
        let inputStream = InputStream.init(data: "test".data(using: .utf8)!)
        let outputStream = OutputStream(url: destination, append: true)
        
        
        let hexKey = "4ba9058b2efc8c7c9c869b6573b725aa8bf67aecb26d3ebd678e624565570e9c"
        let hexIv = "4ae6fcc4dd6ebcdb9076f2396d64da48"
        
        self.sut.encryptFromStream(
            input: inputStream,
            output: outputStream!,
            key: self.utils.hexStringToBytes(hexKey),
            iv:  self.utils.hexStringToBytes(hexIv),
            callback: {(error, status) in
                XCTAssertEqual(status, EncryptResultStatus.Success)
                let result = try! Data(contentsOf: destination).toHexString()
                
                XCTAssertEqual(result, "5d14c5cf")
            }
        )
    }
    
    func testEncryptSync() throws {
        let data = "test".data(using: .utf8)!
        
        
        let hexKey = "4ba9058b2efc8c7c9c869b6573b725aa8bf67aecb26d3ebd678e624565570e9c"
        let hexIv = "4ae6fcc4dd6ebcdb9076f2396d64da48"
        
        let result = try self.sut.encryptData(data: data, key: self.utils.hexStringToBytes(hexKey), iv: self.utils.hexStringToBytes(hexIv))
        
        
        XCTAssertEqual(result.toHexString(), "5d14c5cf")
   
    }
    
    func testDecrypt() throws {
        let encryptedBytes: [UInt8] = [97, 24, 150, 210, 51, 34, 168, 164, 0, 19, 163, 219, 9, 44, 97, 24, 150, 210, 51, 34, 168, 164, 0, 19, 163, 219, 9, 44, 97, 24, 150, 210, 51, 34, 168, 164, 0, 19, 163, 219, 9, 44, 97, 24, 150, 210, 51, 34, 168, 164, 0, 19, 163, 219, 9, 44, 97, 24, 150, 210, 51, 34, 168, 164, 0, 19, 163, 219, 9, 44, 97, 24, 150, 210, 51, 34, 168, 164, 0, 19, 163, 219, 9, 44, 97, 24, 150, 210, 51, 34, 168, 164, 0, 19, 163, 219, 9, 44, 97, 24, 150, 210, 51, 34, 168, 164, 0, 19, 163, 219, 9, 44, 97, 24, 150, 210, 51, 34, 168, 164, 0, 19, 163, 219, 9, 44, 97, 24, 150, 210, 51, 34, 168, 164, 0, 19, 163, 219, 9, 44, 97, 24, 150, 210, 51, 34, 168, 164, 0, 19, 163, 219, 9, 44, 97, 24, 150, 210, 51, 34, 168, 164, 0, 19, 163, 219, 9, 44, 97, 24, 150, 210, 51, 34, 168, 164, 0, 19, 163, 219, 9, 44, 97, 24, 150, 210, 51, 34, 168, 164, 0, 19, 163, 219, 9, 44, 93, 20, 197, 207, 93, 20, 197, 207, 93, 20, 197, 207]
        
        let destination = getTemporaryURL()
        let inputStream = InputStream(data: Data(bytes: encryptedBytes, count: encryptedBytes.count))
        let outputStream = OutputStream(url: destination, append: true)
        
        
        let hexKey = "4ba9058b2efc8c7c9c869b6573b725aa8bf67aecb26d3ebd678e624565570e9c"
        let hexIv = "4ae6fcc4dd6ebcdb9076f2396d64da48"
        
        self.sut.decryptFromStream(
            input: inputStream,
            output: outputStream!,
            key: self.utils.hexStringToBytes(hexKey),
            iv:  self.utils.hexStringToBytes(hexIv),
            callback: {(error, status) in
                XCTAssertEqual(status, DecryptResultStatus.Success)
            }
        )
    }
    
    func testBadIV() throws {
        let destination = getTemporaryURL()
        let inputStream = InputStream.init(data: "teststring".data(using: .utf8)!)
        let outputStream = OutputStream(url: destination, append: true)
        
        
        let hexKey = "4ba9058b2efc8c7c9c869b6573b725aa8bf67aecb26d3ebd678e624565570e9c"
        
        self.sut.encryptFromStream(
            input: inputStream,
            output: outputStream!,
            key: self.utils.hexStringToBytes(hexKey),
            iv:  [UInt8](),
            callback: {(error, status) in
                XCTAssertEqual(status, nil)
                
            }
        )
    }

}
