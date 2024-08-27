//
//  RIPEMD160+Extension.swift
//  
//  Implementation from https://github.com/MiclausCorp/ripemd160-Swift, the repository was deleted on 27/8/24
//
//  Created by Robert Garcia on 27/8/24.
//

import Foundation

#if canImport(Foundation)
import Foundation

/// Hash-based message authentication code extension
public extension RIPEMD160 {
    /// Generate a keyed-hash message authentication code
    /// - Parameters:
    ///   - key: Key bytes
    ///   - message: Message bytes
    /// - Returns: HMAC bytes
    static func hmac(key: Data, message: Data) -> Data {
        var key = key
        key.count = 64 // Truncate to 64 bytes or fill-up with zeros.

        let outerKeyPad = Data(key.map { $0 ^ 0x5c })
        let innerKeyPad = Data(key.map { $0 ^ 0x36 })

        var innerMd = RIPEMD160()
        innerMd.update(data: innerKeyPad)
        innerMd.update(data: message)

        var outerMd = RIPEMD160()
        outerMd.update(data: outerKeyPad)
        outerMd.update(data: innerMd.finalize())

        return outerMd.finalize()
    }
    
    /// Generate a keyed-hash message authentication code
    /// - Parameters:
    ///   - key: Key bytes
    ///   - message: Message `String`
    /// - Returns: HMAC bytes
    static func hmac(key: Data, message: String) -> Data {
        return RIPEMD160.hmac(key: key, message: message.data(using: .utf8)!)
    }
    
    /// Generate a keyed-hash message authentication code
    /// - Parameters:
    ///   - key: Key `String`
    ///   - message: Message `String`
    /// - Returns: HMAC bytes
    static func hmac(key: String, message: String) -> Data {
        return RIPEMD160.hmac(key: key.data(using: .utf8)!, message: message)
    }
    
    /// Generate a keyed-hash message authentication code
    /// - Parameters:
    ///   - key: Key `String`
    ///   - message: Message bytes
    /// - Returns: HMAC bytes
    static func hmac(key: String, message: Data) -> Data {
        return RIPEMD160.hmac(key: key.data(using: .utf8)!, message: message)
    }
}
#endif

#if canImport(Foundation)
import Foundation
/// RIPEMD160 Swift "one-shot" functions to compute the hash of a message extension
public extension RIPEMD160 {
    /// Compute hash from `Data`
    /// - Parameter message: Input bytes
    /// - Returns: Hash digest
    static func hash(_ message: Data) -> Data {
        var md = RIPEMD160()
        md.update(data: message)
        return md.finalize()
    }
    
    /// Compute hash from `String`
    /// - Parameter message: Input string
    /// - Returns: Hash digest
    static func hash(_ message: String) -> Data {
        return RIPEMD160.hash(message.data(using: .utf8)!)
    }
}

#endif
