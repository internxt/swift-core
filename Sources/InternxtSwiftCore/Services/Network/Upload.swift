//
//  File.swift
//  
//
//  Created by Robert Garcia on 4/8/23.
//

import Foundation

@available(macOS 10.15, *)
struct Upload {
    private let encrypt = Encrypt()
    private let cryptoUtils = CryptoUtils()
    private let networkApi = NetworkAPI()
    func start( bucketId: String, mnemonic: String, filepath: String) throws -> Void {
        let inputStream = InputStream(url: URL(fileURLWithPath: filepath))
        
        let outputFilePath = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("enc")
        
        let outputStream = OutputStream(url: outputFilePath, append: true)
        
        // Generate random index, IV and fileKey
        let index = cryptoUtils.getRandomBytes(32)
        if(index == nil) {
            throw UploadError.InvalidIndex
        }
        let fullHexString = cryptoUtils.bytesToHexString(index!)
        let hexIv = fullHexString.prefix(upTo: fullHexString.index(fullHexString.startIndex, offsetBy: 32))
        let iv = cryptoUtils.hexStringToBytes(String(hexIv))
        
        let fileKey = try encrypt.generateFileKey(mnemonic: mnemonic, bucketId: bucketId, index: index!)
    }
}
