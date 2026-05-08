import XCTest
@testable import InternxtSwiftCore

@available(macOS 10.15, *)
final class InternxtAESCipherTests: XCTestCase {
    
    var cipher: InternxtAESCipher!
    
    override func setUp() {
        super.setUp()
        cipher = InternxtAESCipher()
    }
    
    override func tearDown() {
        cipher = nil
        super.tearDown()
    }
    
    func testEncryptDecryptSymmetry() throws {
        let plaintext = "test-mnemonic-pattern-secret"
        let password = "test-password-123"
        
        // 1. Encrypt
        let encryptedBase64 = try cipher.encrypt(plaintext: plaintext, password: password)
        XCTAssertFalse(encryptedBase64.isEmpty)
        
        // 2. Decrypt
        let decryptedText = try cipher.decrypt(cipherBase64: encryptedBase64, password: password)
        XCTAssertEqual(decryptedText, plaintext)
    }
    
    func testDecryptWithWrongPasswordThrows() throws {
        let plaintext = "secret-message"
        let correctPassword = "correct-password"
        let wrongPassword = "wrong-password"
        
        let encryptedBase64 = try cipher.encrypt(plaintext: plaintext, password: correctPassword)
        
        XCTAssertThrowsError(try cipher.decrypt(cipherBase64: encryptedBase64, password: wrongPassword)) { error in
            XCTAssertNotNil(error)
        }
    }
    
    func testDecryptInvalidBase64Throws() {
        let invalidBase64 = "this-is-not-base64!"
        let password = "password"
        
        XCTAssertThrowsError(try cipher.decrypt(cipherBase64: invalidBase64, password: password)) { error in
            XCTAssertEqual(error as? InternxtAESError, InternxtAESError.invalidCipherBase64)
        }
    }
    
    func testDecryptShortPayloadThrows() {
        // Payload needs to be at least 64(salt) + 16(iv) + 16(tag) = 96 bytes.
        // Let's create a 95-byte payload.
        let shortData = Data(repeating: 0, count: 95)
        let shortBase64 = shortData.base64EncodedString()
        let password = "password"
        
        XCTAssertThrowsError(try cipher.decrypt(cipherBase64: shortBase64, password: password)) { error in
            XCTAssertEqual(error as? InternxtAESError, InternxtAESError.invalidPayloadLength)
        }
    }
    
    func testGenerateRandomUrlSafeString() throws {
        let length = 8
        let randomString = try cipher.generateRandomUrlSafeString(length: length)
        
        XCTAssertEqual(randomString.count, length)
        // Ensure no standard base64 characters like '+' or '/' or '='
        XCTAssertFalse(randomString.contains("+"))
        XCTAssertFalse(randomString.contains("/"))
        XCTAssertFalse(randomString.contains("="))
    }
}
