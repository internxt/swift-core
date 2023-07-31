//
//  HMAC.swift
//  
//
//  Created by Robert Garcia on 31/7/23.
//

import Foundation
import CryptoKit

enum HashInput {
    case message ([UInt8])
    case messages (Array<[UInt8]>)
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
struct HMAC {
    
    func sha512(inputs: Array<[UInt8]>) -> [UInt8] {
        
        var hash = SHA512.init()
        for (_, input) in inputs.enumerated() {
            hash.update(data: input)
        }
        
        let digest = hash.finalize()
        var result = [UInt8]()
        digest.withUnsafeBytes {bytes in
            result.append(contentsOf: bytes)
        }
        
        return result
    }
    
    func sha256(inputs: Array<[UInt8]>) -> [UInt8] {
        
        var hash = SHA256.init()
        for (_, input) in inputs.enumerated() {
            hash.update(data: input)
        }
        
        let digest = hash.finalize()
        var result = [UInt8]()
        digest.withUnsafeBytes {bytes in
            result.append(contentsOf: bytes)
        }
        
        return result
    }
    
   
    
    
}

