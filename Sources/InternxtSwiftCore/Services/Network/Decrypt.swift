//
//  File.swift
//  
//
//  Created by Robert Garcia on 23/8/23.
//

import Foundation
import CryptoKit


struct DecryptConfig {
    let key: [UInt8]
    let iv: [UInt8]
}



@available(macOS 10.15, *)
public struct Decrypt {
    
    private let cryptoUtils = CryptoUtils()
    private let keyDerivation = KeyDerivation()
    private let hmac = HMAC()
    
    public init() {
        
    }
    func start(input: InputStream, output: OutputStream, config: DecryptConfig) async throws -> DecryptResultStatus  {
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DecryptResultStatus, Error>) -> Void in
            AESCipher().decryptFromStream(input: input, output: output, key: config.key, iv: config.iv, callback: {(error, status) in
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
    
    public func decrypt(base64String: String, password: String, rounds: Int = 2145) throws -> String {

        if base64String.isEmpty    {
            throw CryptoError.emptyBase64String
        }
        
        guard let data = Data(base64Encoded: base64String) else {
            throw CryptoError.invalidBase64String
        }
        
        
        let salt = data.prefix(64)
        let iv = data[64..<80]
        let tag = data[80..<96]
        let text = data.suffix(from: 96)
        
        
        let key = keyDerivation.pbkdf2(
            password: password,
            salt: salt,
            rounds: rounds,
            derivedKeyLength: 32
        )
        
        let sealedBox = try AES.GCM.SealedBox(
                            nonce: AES.GCM.Nonce(data: iv),
                            ciphertext: text,
                            tag: tag
        )
        
        let decryptedData = try AES.GCM.open(sealedBox, using: SymmetricKey(data: key))
        
        return String(decoding: decryptedData, as: UTF8.self)
    }
}
