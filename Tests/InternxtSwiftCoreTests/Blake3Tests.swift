//
//  Blake3Tests.swift
//  InternxtSwiftCoreTests
//
//  Official BLAKE3 test vectors from BLAKE3-team/BLAKE3 (test_vectors/test_vectors.json).
//  Input is the repeating byte pattern 0,1,...,250,0,1,... of the given length.
//

import XCTest
@testable import InternxtSwiftCore

@available(macOS 10.15, *)
final class Blake3Tests: XCTestCase {

    private static let context = "BLAKE3 2019-12-27 16:29:52 test vectors context"

    /// (inputLength, expected hash, expected derive_key), first 32 bytes of each.
    private static let vectors: [(Int, String, String)] = [
        (0, "af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262", "2cc39783c223154fea8dfb7c1b1660f2ac2dcbd1c1de8277b0b0dd39b7e50d7d"),
        (1, "2d3adedff11b61f14c886e35afa036736dcd87a74d27b5c1510225d0f592e213", "b3e2e340a117a499c6cf2398a19ee0d29cca2bb7404c73063382693bf66cb06c"),
        (2, "7b7015bb92cf0b318037702a6cdd81dee41224f734684c2c122cd6359cb1ee63", "1f166565a7df0098ee65922d7fea425fb18b9943f19d6161e2d17939356168e6"),
        (3, "e1be4d7a8ab5560aa4199eea339849ba8e293d55ca0a81006726d184519e647f", "440aba35cb006b61fc17c0529255de438efc06a8c9ebf3f2ddac3b5a86705797"),
        (4, "f30f5ab28fe047904037f77b6da4fea1e27241c5d132638d8bedce9d40494f32", "f46085c8190d69022369ce1a18880e9b369c135eb93f3c63550d3e7630e91060"),
        (5, "b40b44dfd97e7a84a996a91af8b85188c66c126940ba7aad2e7ae6b385402aa2", "1f24eda69dbcb752847ec3ebb5dd42836d86e58500c7c98d906ecd82ed9ae47f"),
        (6, "06c4e8ffb6872fad96f9aaca5eee1553eb62aed0ad7198cef42e87f6a616c844", "be96b30b37919fe4379dfbe752ae77b4f7e2ab92f7ff27435f76f2f065f6a5f4"),
        (7, "3f8770f387faad08faa9d8414e9f449ac68e6ff0417f673f602a646a891419fe", "dc3b6485f9d94935329442916b0d059685ba815a1fa2a14107217453a7fc9f0e"),
        (8, "2351207d04fc16ade43ccab08600939c7c1fa70a5c0aaca76063d04c3228eaeb", "2b166978cef14d9d438046c720519d8b1cad707e199746f1562d0c87fbd32940"),
        (63, "e9bc37a594daad83be9470df7f7b3798297c3d834ce80ba85d6e207627b7db7b", "b6451e30b953c206e34644c6803724e9d2725e0893039cfc49584f991f451af3"),
        (64, "4eed7141ea4a5cd4b788606bd23f46e212af9cacebacdc7d1f4c6dc7f2511b98", "a5c4a7053fa86b64746d4bb688d06ad1f02a18fce9afd3e818fefaa7126bf73e"),
        (65, "de1e5fa0be70df6d2be8fffd0e99ceaa8eb6e8c93a63f2d8d1c30ecb6b263dee", "51fd05c3c1cfbc8ed67d139ad76f5cf8236cd2acd26627a30c104dfd9d3ff8a8"),
        (127, "d81293fda863f008c09e92fc382a81f5a0b4a1251cba1634016a0f86a6bd640d", "c91c090ceee3a3ac81902da31838012625bbcd73fcb92e7d7e56f78deba4f0c3"),
        (128, "f17e570564b26578c33bb7f44643f539624b05df1a76c81f30acd548c44b45ef", "81720f34452f58a0120a58b6b4608384b5c51d11f39ce97161a0c0e442ca0225"),
        (129, "683aaae9f3c5ba37eaaf072aed0f9e30bac0865137bae68b1fde4ca2aebdcb12", "938d2d4435be30eafdbb2b7031f7857c98b04881227391dc40db3c7b21f41fc1"),
        (1023, "10108970eeda3eb932baac1428c7a2163b0e924c9a9e25b35bba72b28f70bd11", "74a16c1c3d44368a86e1ca6df64be6a2f64cce8f09220787450722d85725dea5"),
        (1024, "42214739f095a406f3fc83deb889744ac00df831c10daa55189b5d121c855af7", "7356cd7720d5b66b6d0697eb3177d9f8d73a4a5c5e968896eb6a689684302706"),
        (1025, "d00278ae47eb27b34faecf67b4fe263f82d5412916c1ffd97c8cb7fb814b8444", "effaa245f065fbf82ac186839a249707c3bddf6d3fdda22d1b95a3c970379bcb"),
        (2048, "e776b6028c7cd22a4d0ba182a8bf62205d2ef576467e838ed6f2529b85fba24a", "7b2945cb4fef70885cc5d78a87bf6f6207dd901ff239201351ffac04e1088a23"),
        (2049, "5f4d72f40d7a5f82b15ca2b2e44b1de3c2ef86c426c95c1af0b6879522563030", "2ea477c5515cc3dd606512ee72bb3e0e758cfae7232826f35fb98ca1bcbdf273"),
        (3072, "b98cb0ff3623be03326b373de6b9095218513e64f1ee2edd2525c7ad1e5cffd2", "050df97f8c2ead654d9bb3ab8c9178edcd902a32f8495949feadcc1e0480c46b"),
        (3073, "7124b49501012f81cc7f11ca069ec9226cecb8a2c850cfe644e327d22d3e1cd3", "72613c9ec9ff7e40f8f5c173784c532ad852e827dba2bf85b2ab4b76f7079081"),
        (4096, "015094013f57a5277b59d8475c0501042c0b642e531b0a1c8f58d2163229e969", "1e0d7f3db8c414c97c6307cbda6cd27ac3b030949da8e23be1a1a924ad2f25b9"),
        (4097, "9b4052b38f1c5fc8b1f9ff7ac7b27cd242487b3d890d15c96a1c25b8aa0fb995", "aca51029626b55fda7117b42a7c211f8c6e9ba4fe5b7a8ca922f34299500ead8"),
        (5120, "9cadc15fed8b5d854562b26a9536d9707cadeda9b143978f319ab34230535833", "7a7acac8a02adcf3038d74cdd1d34527de8a0fcc0ee3399d1262397ce5817f60"),
        (5121, "628bd2cb2004694adaab7bbd778a25df25c47b9d4155a55f8fbd79f2fe154cff", "b07f01e518e702f7ccb44a267e9e112d403a7b3f4883a47ffbed4b48339b3c34"),
        (6144, "3e2e5b74e048f3add6d21faab3f83aa44d3b2278afb83b80b3c35164ebeca205", "2a95beae63ddce523762355cf4b9c1d8f131465780a391286a5d01abb5683a15"),
        (6145, "f1323a8631446cc50536a9f705ee5cb619424d46887f3c376c695b70e0f0507f", "379bcc61d0051dd489f686c13de00d5b14c505245103dc040d9e4dd1facab8e5"),
        (7168, "61da957ec2499a95d6b8023e2b0e604ec7f6b50e80a9678b89d2628e99ada77a", "11c37a112765370c94a51415d0d651190c288566e295d505defdad895dae2237"),
        (7169, "a003fc7a51754a9b3c7fae0367ab3d782dccf28855a03d435f8cfe74605e7817", "554b0a5efea9ef183f2f9b931b7497995d9eb26f5c5c6dad2b97d62fc5ac31d9"),
        (8192, "aae792484c8efe4f19e2ca7d371d8c467ffb10748d8a5a1ae579948f718a2a63", "ad01d7ae4ad059b0d33baa3c01319dcf8088094d0359e5fd45d6aeaa8b2d0c3d"),
        (8193, "bab6c09cb8ce8cf459261398d2e7aef35700bf488116ceb94a36d0f5f1b7bc3b", "af1e0346e389b17c23200270a64aa4e1ead98c61695d917de7d5b00491c9b0f1"),
        (16384, "f875d6646de28985646f34ee13be9a576fd515f76b5b0a26bb324735041ddde4", "160e18b5878cd0df1c3af85eb25a0db5344d43a6fbd7a8ef4ed98d0714c3f7e1"),
        (31744, "62b6960e1a44bcc1eb1a611a8d6235b6b4b78f32e7abc4fb4c6cdcce94895c47", "39772aef80e0ebe60596361e45b061e8f417429d529171b6764468c22928e28e"),
        (102400, "bc3e3d41a1146b069abffad3c0d44860cf664390afce4d9661f7902e7943e085", "4652cff7a3f385a6103b5c260fc1593e13c778dbe608efb092fe7ee69df6e9c6")
    ]

    private func input(length: Int) -> [UInt8] {
        (0..<length).map { UInt8($0 % 251) }
    }

    private func hex(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }

    func testHashVectors() {
        for (length, expected, _) in Self.vectors {
            XCTAssertEqual(hex(Blake3.hash(input(length: length))), expected, "hash, input_len \(length)")
        }
    }

    func testDeriveKeyVectors() {
        for (length, _, expected) in Self.vectors {
            let derived = Blake3.deriveKey(context: Self.context, material: input(length: length))
            XCTAssertEqual(hex(derived), expected, "derive_key, input_len \(length)")
        }
    }
}
