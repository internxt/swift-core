//
//  MailKeystore.swift
//  InternxtSwiftCore
//
//  Created by Xavier Abad Gomez on 14/09/2026.
//

import Foundation
import CryptoKit

public enum MailKeystoreError: Error, LocalizedError {
    case invalidBase64(field: String)
    case invalidEncryptedKeyLength(Int)
    case decryptionFailed
    case unexpectedPrivateKeyLength(Int)

    public var errorDescription: String? {
        switch self {
        case .invalidBase64(let field):
            return "\(field) is not valid base64"
        case .invalidEncryptedKeyLength(let count):
            return "The encrypted private key is \(count) bytes, expected \(MailKeystore.encryptedPrivateKeyLength)"
        case .decryptionFailed:
            return "Could not open the encryption keystore: wrong mnemonic, address or public key"
        case .unexpectedPrivateKeyLength(let count):
            return "The decrypted private key is \(count) bytes, expected \(MailKeystore.privateKeyLength)"
        }
    }
}

@available(macOS 10.15, *)
public enum MailKeystore {

    /// Domain separator for the keystore key. A single differing character yields a
    /// different key, so this is copied verbatim from the JS library.
    static let encryptionKeystoreContext =
        "CRYPTO library 2025-07-30 16:18:03 key for opening encryption keys keystore"

    static let encryptionKeystoreType = "Encryption"
    static let encryptedPrivateKeyLength = 60
    static let privateKeyLength = 32
    static let tagLength = 16
    static let nonceLength = 12

    /// Recovers the 32-byte X-Wing seed the mail bridge needs.
    ///
    /// - Parameters:
    ///   - address: the mailbox address from the Mail API — **not** the Drive account
    ///     email. It is part of the AAD, so the wrong one fails authentication.
    ///   - publicKey: the account public key exactly as the API returned it, base64 and
    ///     unmodified: the AAD covers the encoded form, not the decoded bytes.
    ///   - encryptedPrivateKey: `encryptionPrivateKey` from the API.
    ///   - mnemonic: the user mnemonic.
    public static func openEncryptionKeystore(
        address: String,
        publicKey: String,
        encryptedPrivateKey: String,
        mnemonic: String
    ) throws -> [UInt8] {
        guard let blob = Data(base64Encoded: encryptedPrivateKey) else {
            throw MailKeystoreError.invalidBase64(field: "encryptionPrivateKey")
        }
        guard blob.count == encryptedPrivateKeyLength else {
            throw MailKeystoreError.invalidEncryptedKeyLength(blob.count)
        }

        let entropy = try CryptoUtils().mnemonicToEntropy(mnemonic)
        let keystoreKey = Blake3.deriveKey(context: encryptionKeystoreContext, material: entropy)

        // The JS library appends the IV instead of prepending it, so the layout is
        // ciphertext || tag || iv rather than the more usual iv || ciphertext || tag.
        let ciphertextEnd = blob.count - tagLength - nonceLength
        let ciphertext = blob.prefix(ciphertextEnd)
        let tag = blob.dropFirst(ciphertextEnd).prefix(tagLength)
        let nonce = blob.suffix(nonceLength)

        // AAD binds the blob to this address, keystore type and public key.
        let authenticating = Data((address + encryptionKeystoreType + publicKey).utf8)

        do {
            let box = try AES.GCM.SealedBox(
                nonce: try AES.GCM.Nonce(data: nonce),
                ciphertext: ciphertext,
                tag: tag
            )
            let opened = try AES.GCM.open(
                box,
                using: SymmetricKey(data: keystoreKey),
                authenticating: authenticating
            )
            guard opened.count == privateKeyLength else {
                throw MailKeystoreError.unexpectedPrivateKeyLength(opened.count)
            }
            return [UInt8](opened)
        } catch let error as MailKeystoreError {
            throw error
        } catch {
            throw MailKeystoreError.decryptionFailed
        }
    }
}
