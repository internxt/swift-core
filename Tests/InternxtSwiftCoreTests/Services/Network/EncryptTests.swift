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
    
    
    func testEncryptStringCorrectly2() throws {
        let ivHex = "22429e1c6b59ef06751f9b2c9d2aaee1"
        let saltHex = "45394ec93a9dda6abeb34a6cc6cbcd614a51bdc42e9ed603ee087698bb9c13aae62fa974a6b8a16b2c12150de56f584c068c28b6dd00ee996fb64991101c6195"
        let expectedBase64 = "RTlOyTqd2mq+s0psxsvNYUpRvcQuntYD7gh2mLucE6rmL6l0prihaywSFQ3lb1hMBowott0A7plvtkmREBxhlSJCnhxrWe8GdR+bLJ0qruEpN9n67xeuMUB/myfxTPIY7z++/U0yxlR2+1RiFC9dwFVc"
        
        let result = try sut.encrypt(string: "textTEXTtext123123", password: "passwordPASS123!lokqfqwf", salt: cryptoUtils.hexStringToBytes(saltHex), iv: Data(cryptoUtils.hexStringToBytes(ivHex)), rounds: 2000)
        
        XCTAssertEqual(result.base64EncodedString(), expectedBase64)
    }
    
    
    func testEncryptStringCorrectly3() throws {
        let ivHex = "d5e2083f9a5394d1d2414bd520dd25e3"
        let saltHex = "c2c60d255c5258ee4d83ae15d532191e5545ff1a5ae02cd8d348f60e59f980e908dbdcdfc4b93f57b4f0c6d35dfabce8c01637691082ddaf87b55ba90662b796"
        let expectedBase64 = "wsYNJVxSWO5Ng64V1TIZHlVF/xpa4CzY00j2Dln5gOkI29zfxLk/V7TwxtNd+rzowBY3aRCC3a+HtVupBmK3ltXiCD+aU5TR0kFL1SDdJeOYpOVh6wFWrxz8TEgaIWgHBmHQP9kq7xt4vUgoWcu/AkKkbgvy"
        
        let result = try sut.encrypt(string: "TEXTtext0000000123444", password: "saltSALT00000", salt: cryptoUtils.hexStringToBytes(saltHex), iv: Data(cryptoUtils.hexStringToBytes(ivHex)), rounds: 5054)
        
        XCTAssertEqual(result.base64EncodedString(), expectedBase64)
    }
    
    func testEncryptStringUsingChunksWithMargin() async throws {
        
        let hexIv = "d5e2083f9a5394d1d2414bd520dd25e3"
        let hexKey = "fdecbc03e63b2433ab750284f4413ec2220eb3c3cea8a87cdddc421550ca9e0f"
        
        let data = "qwefwef3t232322323qwefqwefqwf000099999123!234123__123".data(using: .utf8)!
                   
        let expectedHexEncryptedResult = "655f26c07d7a555bdaaa56c60112b892ff1063f6790fb5c7588b4ace569acde445e428e0a068ded0a9ec5e6c613c01d4d029394f11"
        
        let chunkSizeInBytes = 10
        
        var encryptedChunks: [Data] = []
        let input = InputStream(data: data)
        try await sut.encryptFileIntoChunks(
            chunkSizeInBytes: chunkSizeInBytes,
            totalBytes: data.count,
            inputStream: input,
            key: self.cryptoUtils.hexStringToBytes(hexKey),
            iv: self.cryptoUtils.hexStringToBytes(hexIv)
        ) {encryptedChunk in
            encryptedChunks.append(encryptedChunk)
        }
        
        // We should have 5 chunks of 10 bytes each, and 1 chunk of 3 byte = 53 bytes
        XCTAssertEqual(encryptedChunks[0].count, chunkSizeInBytes)
        XCTAssertEqual(encryptedChunks[1].count, chunkSizeInBytes)
        XCTAssertEqual(encryptedChunks[2].count, chunkSizeInBytes)
        XCTAssertEqual(encryptedChunks[3].count, chunkSizeInBytes)
        XCTAssertEqual(encryptedChunks[4].count, chunkSizeInBytes)
        XCTAssertEqual(encryptedChunks[5].count, 3)
        
        // Check the result
        var totalEncryptedData: Data = Data()
        encryptedChunks.forEach{chunk in
            
            totalEncryptedData.append(chunk)
        }
        
        let totalBytes = data.count
        
        XCTAssertEqual(totalEncryptedData.count, totalBytes)
        XCTAssertEqual(expectedHexEncryptedResult, totalEncryptedData.toHexString())
        
        
    }
    
    
    func testEncryptStringUsingExactChunks() async throws {
        
        let hexIv = "d5e2083f9a5394d1d2414bd520dd25e3"
        let hexKey = "fdecbc03e63b2433ab750284f4413ec2220eb3c3cea8a87cdddc421550ca9e0f"
        
        let data = "PASSWORDpassword123123!!Password123123!!".data(using: .utf8)!
                   
        let expectedHexEncryptedResult = "446910f55d50612cdef91687454ff8c5fc1121b02e5ae5916d8c48ca47c58fb044ef22e8ab62cec3"
        
        let chunkSizeInBytes = 10
        
        var encryptedChunks: [Data] = []
        let input = InputStream(data: data)
        try await sut.encryptFileIntoChunks(
            chunkSizeInBytes: chunkSizeInBytes,
            totalBytes: data.count,
            inputStream: input,
            key: self.cryptoUtils.hexStringToBytes(hexKey),
            iv: self.cryptoUtils.hexStringToBytes(hexIv)
        ) {encryptedChunk in
            encryptedChunks.append(encryptedChunk)
        }
        
        // We should have 4 chunks of 10 bytes each = 40 bytes
        XCTAssertEqual(encryptedChunks[0].count, chunkSizeInBytes)
        XCTAssertEqual(encryptedChunks[1].count, chunkSizeInBytes)
        XCTAssertEqual(encryptedChunks[2].count, chunkSizeInBytes)
        XCTAssertEqual(encryptedChunks[3].count, chunkSizeInBytes)
        
        // Check the result
        var totalEncryptedData: Data = Data()
        encryptedChunks.forEach{chunk in
            
            totalEncryptedData.append(chunk)
        }
        
        let totalBytes = data.count
        
        XCTAssertEqual(totalEncryptedData.count, totalBytes)
        XCTAssertEqual(expectedHexEncryptedResult, totalEncryptedData.toHexString())
        
        
    }
    
    func testEncryptStringShouldFailIfAChunkCallbackThrows() async throws {
        
        let hexIv = "d5e2083f9a5394d1d2414bd520dd25e3"
        let hexKey = "fdecbc03e63b2433ab750284f4413ec2220eb3c3cea8a87cdddc421550ca9e0f"
        
        let data = "PASSWORDpassword123123!!Password123123!!".data(using: .utf8)!
                           
        let chunkSizeInBytes = 10
        
        var encryptedChunks: [Data] = []
        let input = InputStream(data: data)
        do {
            try await sut.encryptFileIntoChunks(
                chunkSizeInBytes: chunkSizeInBytes,
                totalBytes: data.count,
                inputStream: input,
                key: self.cryptoUtils.hexStringToBytes(hexKey),
                iv: self.cryptoUtils.hexStringToBytes(hexIv)
            ) {encryptedChunk in
                if encryptedChunks.count == 1 {
                    // Just throw an error to stop the processing
                    throw EncryptError.NoBytes
                }
                
                encryptedChunks.append(encryptedChunk)
            }
        } catch {
            XCTAssertEqual(encryptedChunks[0].count, chunkSizeInBytes)
            XCTAssertEqual(encryptedChunks.count, 1)
        }
    }
    
    
    func testConcurrentQueue() async throws {
        let concurrentQueue = ConcurrentQueue(maxConcurrentOperations: 2)
        var index = 0;
        concurrentQueue.addOperation{
                index = index + 1
        }
        
        concurrentQueue.addOperation{
            index = index + 1
        }
        
        concurrentQueue.addOperation{
            index = index + 1
        }
        
        concurrentQueue.queue.sync(flags: .barrier) {
            print("INDEX", index)
        }
        
        
    }

}
