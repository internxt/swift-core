//
//  Encrypt.swift
//  
//
//  Created by Robert Garcia on 4/8/23.
//

import Foundation

struct EncryptConfig {
    let key: [UInt8]
    let iv: [UInt8]
}

@available(macOS 10.15, *)
struct Encrypt {
    private let AES = AESCipher()
    private let cryptoUtils = CryptoUtils()
    
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
            throw CryptoError.badIndex()
        }
        let bucketKey = try cryptoUtils.generateBucketKey(mnemonic: mnemonic, bucketId: bucketId);
        let slicedBucketKey = bucketKey.prefix(upTo: bucketKey.index(bucketKey.startIndex, offsetBy: 32))
        let deterministicKey = cryptoUtils.getDeterministicKey(key: Array(slicedBucketKey), data:index);
        return Array(deterministicKey.prefix(upTo: deterministicKey.index(deterministicKey.startIndex, offsetBy: 32)))
      }
}
