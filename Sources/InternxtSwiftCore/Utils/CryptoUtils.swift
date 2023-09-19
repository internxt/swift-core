//
//  CryptoUtils.swift
//  
//
//  Created by Robert Garcia on 31/7/23.
//

import Foundation
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

