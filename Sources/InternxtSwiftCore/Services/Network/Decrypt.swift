//
//  File.swift
//  
//
//  Created by Robert Garcia on 23/8/23.
//

import Foundation


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
}
