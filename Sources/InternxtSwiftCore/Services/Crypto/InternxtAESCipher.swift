//
//  InternxtAESCipher.swift
//  InternxtSwiftCore
//
//  Created by Patricio Tovar on 6/5/26.
//

import Foundation
import CryptoKit

public enum InternxtAESError: Error {
    case invalidCipherBase64
    case invalidPayloadLength
    case decryptionFailed
    case randomBytesFailed
}

@available(macOS 10.15, *)
public struct InternxtAESCipher {
    
   
    private let iterations = 2145
    private let keyLength = 32
    private let saltLength = 64
    private let ivLength = 16
    private let tagLength = 16

    public init() {}

    /// Encrypts a plaintext string using AES-256-GCM and PBKDF2-HMAC-SHA512 derivation.
    ///
    /// - Parameters:
    ///   - plaintext: The text to encrypt.
    ///   - password: The password used for key derivation.
    /// - Returns: Standard Base64 encoded string: `[ salt(64) | iv(16) | tag(16) | ciphertext(N) ]`
    public func encrypt(plaintext: String, password: String) throws -> String {
        let plaintextData = Data(plaintext.utf8)
        
        var salt = [UInt8](repeating: 0, count: saltLength)
        let status1 = SecRandomCopyBytes(kSecRandomDefault, saltLength, &salt)
        guard status1 == errSecSuccess else { throw InternxtAESError.randomBytesFailed }
        
        var iv = [UInt8](repeating: 0, count: ivLength)
        let status2 = SecRandomCopyBytes(kSecRandomDefault, ivLength, &iv)
        guard status2 == errSecSuccess else { throw InternxtAESError.randomBytesFailed }
        
      
        let keyDerivator = KeyDerivation()
        let derivedKeyBytes = keyDerivator.pbkdf2(
            password: password,
            salt: salt,
            rounds: iterations,
            derivedKeyLength: keyLength
        )
        let symmetricKey = SymmetricKey(data: derivedKeyBytes)
        
        // AES-256-GCM
        let nonce = try AES.GCM.Nonce(data: iv)
        let sealedBox = try AES.GCM.seal(plaintextData, using: symmetricKey, nonce: nonce)
        
        var finalData = Data()
        finalData.append(contentsOf: salt)
        finalData.append(contentsOf: iv)
        finalData.append(sealedBox.tag)
        finalData.append(sealedBox.ciphertext)
        
       
        return finalData.base64EncodedString()
    }
    
 
    public func decrypt(cipherBase64: String, password: String) throws -> String {
        guard let data = Data(base64Encoded: cipherBase64) else {
            throw InternxtAESError.invalidCipherBase64
        }
        
        let minLength = saltLength + ivLength + tagLength
        guard data.count > minLength else {
            throw InternxtAESError.invalidPayloadLength
        }
        
        let salt = [UInt8](data[0..<saltLength])
        let iv = [UInt8](data[saltLength..<(saltLength + ivLength)])
        let tag = data[(saltLength + ivLength)..<(saltLength + ivLength + tagLength)]
        let ciphertext = data[(saltLength + ivLength + tagLength)...]
        
        // Derive key
        let keyDerivator = KeyDerivation()
        let derivedKeyBytes = keyDerivator.pbkdf2(
            password: password,
            salt: salt,
            rounds: iterations,
            derivedKeyLength: keyLength
        )
        let symmetricKey = SymmetricKey(data: derivedKeyBytes)
        
        // AES-256-GCM decryption
        let nonce = try AES.GCM.Nonce(data: iv)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
        
        guard let plaintext = String(data: decryptedData, encoding: .utf8) else {
            throw InternxtAESError.decryptionFailed
        }
        
        return plaintext
    }
    

    public func generateRandomUrlSafeString(length: Int) throws -> String {
        if length <= 0 { return "" }
        let numBytes = Int(ceil(Double(length * 3) / 4.0))
        var bytes = [UInt8](repeating: 0, count: numBytes)
        
        let status = SecRandomCopyBytes(kSecRandomDefault, numBytes, &bytes)
        guard status == errSecSuccess else {
            throw InternxtAESError.randomBytesFailed
        }
        
        let base64 = Data(bytes).base64EncodedString()
        let urlSafe = base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        return String(urlSafe.prefix(length))
    }
}
