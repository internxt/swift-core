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
    
    private let cryptoUtils = CryptoUtils()
    private let keyDerivation = KeyDerivation()
    private let hmac = HMAC()
    
    public init() {
        
    }
    func start(input: InputStream, output: OutputStream, config: EncryptConfig) async throws -> EncryptResultStatus  {
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<EncryptResultStatus, Error>) -> Void in
            AESCipher().encryptFromStream(input: input, output: output, key: config.key, iv: config.iv, callback: {(error, status) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let status = status {
                    continuation.resume(returning: status)
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
        
        stream.close()
        
        return hmac.ripemd160(message: Data(sha256Hash))
    }
    
    
    public func encrypt(string: String, password: String, salt: [UInt8], iv: Data, rounds: Int = 2145) throws -> Data{

        
        let key = keyDerivation.pbkdf2(password: password, salt: salt, rounds: rounds, derivedKeyLength: 32)
        let sealedMessage = try AES.GCM.seal(Data(string.utf8), using: SymmetricKey(data: key), nonce: AES.GCM.Nonce(data: iv))
            
        var mergedData = Data()
        
        mergedData.append(salt, count: salt.count)
        mergedData.append(Data(iv))
        mergedData.append(sealedMessage.tag)
        mergedData.append(sealedMessage.ciphertext)
        
        
        return mergedData
    }
}
