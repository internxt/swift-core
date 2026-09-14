//
//  Blake3.swift
//  InternxtSwiftCore
//
//  Thin Swift surface over the vendored official BLAKE3 C implementation.
//

import Foundation
import CBlake3

@available(macOS 10.15, *)
public enum Blake3 {

    /// BLAKE3 in key derivation mode.
    ///
    /// This is not a hash of `context` concatenated with `material`: derive_key is a
    /// distinct mode with its own internal flags, so it cannot be emulated with a plain
    /// hash. The context string is a domain separator and must match the producer's
    /// byte for byte.
    public static func deriveKey(context: String, material: [UInt8], outputLength: Int = 32) -> [UInt8] {
        var hasher = blake3_hasher()
        blake3_hasher_init_derive_key(&hasher, context)

        if !material.isEmpty {
            material.withUnsafeBytes { buffer in
                blake3_hasher_update(&hasher, buffer.baseAddress, buffer.count)
            }
        }

        var output = [UInt8](repeating: 0, count: outputLength)
        output.withUnsafeMutableBytes { buffer in
            blake3_hasher_finalize(&hasher, buffer.bindMemory(to: UInt8.self).baseAddress, buffer.count)
        }
        return output
    }

    /// Plain BLAKE3 hashing, used by the test vectors.
    public static func hash(_ input: [UInt8], outputLength: Int = 32) -> [UInt8] {
        var hasher = blake3_hasher()
        blake3_hasher_init(&hasher)

        if !input.isEmpty {
            input.withUnsafeBytes { buffer in
                blake3_hasher_update(&hasher, buffer.baseAddress, buffer.count)
            }
        }

        var output = [UInt8](repeating: 0, count: outputLength)
        output.withUnsafeMutableBytes { buffer in
            blake3_hasher_finalize(&hasher, buffer.bindMemory(to: UInt8.self).baseAddress, buffer.count)
        }
        return output
    }
}
