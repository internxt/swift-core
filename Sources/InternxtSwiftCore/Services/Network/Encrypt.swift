//
//  Encrypt.swift
//  
//
//  Created by Robert Garcia on 4/8/23.
//

import Foundation
import CryptoKit

struct EncryptConfig {
    let key: [UInt8]
    let iv: [UInt8]
}

@available(macOS 10.15, *)
public struct Encrypt {
    private let AES = AESCipher()
    private let cryptoUtils = CryptoUtils()
    private let hmac = HMAC()
    
    func start(input: InputStream, output: OutputStream, config: EncryptConfig) async throws -> EncryptResultStatus  {
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EncryptResultStatus, Error>) -> Void in
            AES.encryptFromStream(input: input, output: output, key: config.key, iv: config.iv, callback: {(error, status) in
                if(error != nil) {
                    
                    continuation.resume(throwing: error!)
                    return
                }
                
                if(status != nil) {
                    continuation.resume(returning: status!)
                }
                
            })
        }
        
    }
    
    func generateFileKey(mnemonic: String, bucketId: String, index: [UInt8]) throws -> [UInt8] {
        if(index.count != 32) {
            throw CryptoError.badIndex("Index should be 32 bytes length")
        }
        let bucketKey = try cryptoUtils.generateBucketKey(mnemonic: mnemonic, bucketId: bucketId);
        let slicedBucketKey = bucketKey.prefix(upTo: bucketKey.index(bucketKey.startIndex, offsetBy: 32))
        let deterministicKey = cryptoUtils.getDeterministicKey(key: Array(slicedBucketKey), data:index);
        return Array(deterministicKey.prefix(upTo: deterministicKey.index(deterministicKey.startIndex, offsetBy: 32)))
    }
    
    /// Creates a RIPEMD160 hash from a SHA256 hash created from the stream content
    func getFileContentHash(stream: InputStream) -> Data {
        var hasher = SHA256.init()
        
        stream.open()

        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)

        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            let bufferPointer = UnsafeRawBufferPointer(start: buffer, count: read)
            hasher.update(bufferPointer: bufferPointer)
        }

        let digest = hasher.finalize()
        
        var sha256Hash = [UInt8]()
        digest.withUnsafeBytes {bytes in
            sha256Hash.append(contentsOf: bytes)
        }
        
        return hmac.ripemd160(message: Data(sha256Hash))
    }
}
