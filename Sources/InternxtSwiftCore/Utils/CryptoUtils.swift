//
//  CryptoUtils.swift
//  
//
//  Created by Robert Garcia on 31/7/23.
//

import Foundation
import CryptoKit
import IDZSwiftCommonCrypto

@available(macOS 10.15, *)
public struct CryptoUtils {
    private let keyDerivation = KeyDerivation()
    private let hmac = HMAC()
    
    public init() {
        
    }
    
    public func hexStringToBytes(_ hexString: String) -> [UInt8] {
        return arrayFrom(hexString: hexString)
    }
    
    public func bytesToHexString(_ bytes: [UInt8]) -> String {
        let format = "%02hhx"
        return bytes.map { String(format: format, $0) }.joined()
    }
    
    
    public func mnemonicToSeed(mnemonic: String, password: String) -> [UInt8] {
        return keyDerivation.pbkdf2(
            password: mnemonic,
            salt: "mnemonic",
            rounds: 2048,
            derivedKeyLength: 64
        );
    }
    
    public func getDeterministicKey(key: [UInt8], data: [UInt8]) -> [UInt8] {
        return hmac.sha512(inputs: [key, data])
    }
    
    public func generateBucketKey(mnemonic: String, bucketId: String) throws -> [UInt8] {
        let isValidHex = bucketId.isValidHex
    
        if(!isValidHex) {
            throw ExtensionError.InvalidHex
        }
        let seed = self.mnemonicToSeed(mnemonic: mnemonic, password: "")
        return getDeterministicKey(key: seed, data: self.hexStringToBytes(bucketId));
    }
    
    public func getRandomBytes(_ howMany: Int) -> [UInt8]? {
        var bytes = [UInt8](repeating: 0, count:howMany)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        if status == errSecSuccess {
            return bytes
        } else {
            return nil
        }
    }
    
    /// Recovers the raw BIP39 entropy behind a mnemonic.
    ///
    /// Not to be confused with `mnemonicToSeed`, which is the PBKDF2 seed used for file
    /// encryption. The mail keystore is unlocked with the *entropy*, so the two are not
    /// interchangeable: a 24-word mnemonic yields 32 bytes here and 64 there.
    public func mnemonicToEntropy(_ mnemonic: String) throws -> [UInt8] {
        let words = mnemonic
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        guard words.count % 3 == 0, (12...24).contains(words.count) else {
            throw BIP39Error.invalidWordCount(words.count)
        }

        // Each word is an 11-bit index into the canonical wordlist.
        var bits: [Bool] = []
        bits.reserveCapacity(words.count * 11)
        for word in words {
            guard let index = String.englishMnemonicsList.firstIndex(of: word) else {
                throw BIP39Error.unknownWord(word)
            }
            for shift in stride(from: 10, through: 0, by: -1) {
                bits.append((index >> shift) & 1 == 1)
            }
        }

        // The tail is a checksum over the entropy, one bit per 32 entropy bits.
        let checksumLength = bits.count / 33
        let entropyLength = bits.count - checksumLength
        let entropy = packIntoBytes(Array(bits[0..<entropyLength]))
        let expected = packIntoBytes(Array(bits[entropyLength...]))

        let digest = SHA256.hash(data: Data(entropy))
        let actual = packIntoBytes(Array(bitsOf(Array(digest))[0..<checksumLength]))

        guard actual == expected else {
            throw BIP39Error.checksumMismatch
        }

        return entropy
    }

    private func bitsOf(_ bytes: [UInt8]) -> [Bool] {
        bytes.flatMap { byte in (0..<8).map { (byte >> (7 - $0)) & 1 == 1 } }
    }

    private func packIntoBytes(_ bits: [Bool]) -> [UInt8] {
        stride(from: 0, to: bits.count, by: 8).map { start in
            var byte: UInt8 = 0
            for offset in 0..<min(8, bits.count - start) where bits[start + offset] {
                byte |= 1 << (7 - offset)
            }
            return byte
        }
    }

    public func validate(mnemonic: String) -> Bool {
        let normalizedMnemonic = mnemonic.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let mnemonicComponents = normalizedMnemonic.components(separatedBy: " ")
        guard !mnemonicComponents.isEmpty else {
          return false
        }

        if String.englishMnemonics.contains(mnemonicComponents[0]) {
          for mnemonicComponent in mnemonicComponents {
            guard String.englishMnemonics.contains(mnemonicComponent) else {
              return false
            }
          }
          return true
        } else {
          return false
        }
      }
}

public enum BIP39Error: Error, LocalizedError {
    case invalidWordCount(Int)
    case unknownWord(String)
    case checksumMismatch

    public var errorDescription: String? {
        switch self {
        case .invalidWordCount(let count): return "A mnemonic must be 12 to 24 words in multiples of 3, got \(count)"
        case .unknownWord: return "The mnemonic contains a word outside the BIP39 English wordlist"
        case .checksumMismatch: return "The mnemonic checksum does not match"
        }
    }
}
