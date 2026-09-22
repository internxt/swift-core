//
//  MailKeystoreTests.swift
//  InternxtSwiftCoreTests
//
//  Cross-language fixture: the keystore below was produced by internxt-crypto 1.6.1
//  (`createEncryptionAndRecoveryKeystores`), the same library the web client uses.
//  If this passes, the whole chain matches JS — BIP39 entropy, BLAKE3 derive_key,
//  the AAD and the trailing-IV AES-GCM layout.
//
//  The mnemonic is a published BIP39 test vector, not anyone's account.
//

import XCTest
@testable import InternxtSwiftCore

@available(macOS 10.15, *)
final class MailKeystoreTests: XCTestCase {

    private let mnemonic = "legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth useful legal will"
    private let address = "alice@inxt.eu"
    private let publicKey = "16mD+GQmpgkqdMbNppt8IuOMHDgosanOtJWuc2mJZ7kLZVkKEfhbO1sLUmUB3PecgHy06UzEK2vLHadcOFfFGHil5cE2g+IGYdBtfVybIFWA4VkVqmBu5bcrdtI92/bARsYaEqS/SaSiTgeynjlRM8i0Dotk/CRuU6NEiexqCVq9NaJPuqOvMzYMVamfcrWoVFOeAvFJDAy4cIfLxJxYoSpXNfhYR3Vs8EOSeOaaoSlC9qrGAFmDLKK4gKIU8sqPfYqADYYe8lmB3PiIpwJa3zcpM1pr4QBWZBotRhmOzhEjYKCxfGlnyOwhgTGRKnhS/Ldc//N0WzeTPiUMkqYgzOs7IKPM3VPKiBqlH/Ngs9zFLLA6BWgGM5VR2hWsRdBmvBAnrbElIAHIqHRIUssk5mVgDFiii0hcZuRxxRis7nxNzOKoiQwS54xyl2yiZLCk7apj4+ah3ICB/3E4SZGD8YSxlOB7snObklJxmsxreAPIkYZpEptJvtoBDlceQxggRkM5oWhgHhNKYjezcAG26NdH5gJS5GHJd0uflei2+YEaC0yQaqSg26LKjWU5dRqiOjyWnfgkMbWRPrkPWQFFvQcLI4pEqKoixxojLabFyIMpjTcYUYdjymkIwPBKBZfDEytDPMkzzcZ2VHsosVRfAgeLIRCOoDyQ4aEAMlxDwaA90FmdiYGeMLFMr7KmiwlRgrcRJWca53oeLWMMDRB1OSFNfTrLrLQSLTyIfewSVdvEEfNqcngXCagsgfh+s6caJYJYDLy8jElP9RCAeWERBWh98DNwecvM7feABEMOnhmo/6B9lqsMCUbFvHxCsvBWIymNnhi7ANSR6kRz94VOC2E4qZVE0xJBmbAGZiKC1jQZbzEO3wJsKPoTvpDIAkkZoiB/ldECTaKy++EjGzS2stRuIKME0HicL9wSxsInr4epJJBY3Fw0H6lDC9x66OzFf8xCDFdXg3hIrYwWQUVQJ9ibKJRBWiC/V2C1j7QTeseMx7ZdowYrXTu1r8VQUSATPgdvAMisp+jAHTvOg2wJhrlHubIJFLxyYIuKU6YqVQym2HFlxDaXxPtYETSIh8RLv5mSygWqZ7kLWnPNzScKQllNSRmQCAaHsgwjbkhSOeFyo8UfNMSNKTsJAIu80lOyoEtAxTeJtOrHC8pH+9FTqSE4PNVkUixC+bpNQSeSLGO92DVB3BGcWijHRFSl2coaG8pl4PDN5xc0RwBBT1qTqPhDZRCgJ6VvSTOlwWCl3bIFMtcPUwVxp1t7EviDlgqNwjhATDWcgrI0QTQ8CIfNS3q7YejBsAsAjuq6+CrP1rB9IbCFvvOg/ckIG9QUtECp1EFKsXJjCQQAqxwxMpdvEYJehAkRxrSutAydO2YwWSy9U7ozNryXRrt3Zvd81+KU+Hw9cpnJazk33HWA30RxX1VtbkqRnucat8fOSSd4qygdOpg+c2k3m7yXsckrzuUEmnuRKOh7V5FGV5xhLsiPEtxp/EVod8o2BNJLmksGArcSTLvFi1VfoTlsxCshgHJqnwno1j+b7kddKhcJ45TUBiXZbHgjOx8MK8nXfTrz/mvEVnzihGToM2JWGqPuRKjwI/qM5J87vT99nj0uMQ1pHw=="
    private let encryptionPrivateKey = "/NvzsE0I2VgKt/37KdFeEqNHgOTcScv3nRW5YPfuAVsv2dQRzrwAdddPqrqSz7M0UtFDnWSOZ9fBuhY0"
    private let expectedSecretKey = "2eIAdFsuEZpBTPx82QXV/pVcIeWNinuQXB2UYtBB5So="

    private func open(
        address: String? = nil,
        publicKey: String? = nil,
        mnemonic: String? = nil
    ) throws -> [UInt8] {
        try MailKeystore.openEncryptionKeystore(
            address: address ?? self.address,
            publicKey: publicKey ?? self.publicKey,
            encryptedPrivateKey: encryptionPrivateKey,
            mnemonic: mnemonic ?? self.mnemonic
        )
    }

    func testMatchesTheJavaScriptImplementation() throws {
        let key = try open()
        XCTAssertEqual(Data(key).base64EncodedString(), expectedSecretKey)
    }

    /// The daemon rejects anything that is not exactly 32 bytes.
    func testYields32Bytes() throws {
        XCTAssertEqual(try open().count, 32)
    }

    /// Every wrong input must fail authentication rather than return plausible bytes:
    /// a silently wrong key would make the bridge serve mail undecrypted.
    func testWrongMnemonicFails() {
        let other = "legal winner thank year wave sausage worth useful legal winner thank yellow"
        XCTAssertThrowsError(try open(mnemonic: other))
    }

    func testWrongAddressFails() {
        XCTAssertThrowsError(try open(address: "mallory@inxt.eu"))
    }

    func testWrongPublicKeyFails() throws {
        var tampered = Array(publicKey)
        tampered[0] = tampered[0] == "A" ? "B" : "A"
        XCTAssertThrowsError(try open(publicKey: String(tampered)))
    }

    func testRejectsMalformedBlob() {
        XCTAssertThrowsError(try MailKeystore.openEncryptionKeystore(
            address: address, publicKey: publicKey,
            encryptedPrivateKey: "bm90LWJhc2U2NA==", mnemonic: mnemonic
        ))
    }

    func testRejectsInvalidBase64() {
        XCTAssertThrowsError(try MailKeystore.openEncryptionKeystore(
            address: address, publicKey: publicKey,
            encryptedPrivateKey: "not-base64!", mnemonic: mnemonic
        ))
    }
}
