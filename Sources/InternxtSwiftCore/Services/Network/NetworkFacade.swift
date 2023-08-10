//
//  File.swift
//  
//
//  Created by Robert Garcia on 4/8/23.
//

import Foundation

@available(macOS 10.15, *)

public struct NetworkFacade {
    private let apiUrl: String
    private let bridgeUser: String
    private let encrypt: Encrypt = Encrypt()
    private let cryptoUtils: CryptoUtils = CryptoUtils()
    private let mnemonic: String
    private let upload: Upload
    
    init(apiUrl: String , bridgeUser: String, userId: String, mnemonic: String, networkAPI: NetworkAPI){
        self.apiUrl = apiUrl
        self.bridgeUser = bridgeUser
        self.mnemonic = mnemonic
        
        self.upload = Upload(networkAPI: networkAPI)
    }
    
    public func uploadFile(input: InputStream, encryptedOutputPath: String, fileSize: Int, bucketId: String, progressHandler: @escaping ProgressHandler) async throws -> FinishUploadResponse {
        // Generate random index, IV and fileKey
        guard let index = cryptoUtils.getRandomBytes(32) else {
            throw UploadError.InvalidIndex
        }
        
        let fullHexString = cryptoUtils.bytesToHexString(index)
        let hexIv = fullHexString.prefix(upTo: fullHexString.index(fullHexString.startIndex, offsetBy: 32))
        let iv = cryptoUtils.hexStringToBytes(String(hexIv))
        
        let fileKey = try encrypt.generateFileKey(mnemonic: mnemonic, bucketId: bucketId, index: index)
        
        guard let encryptedOutputStream = OutputStream(toFileAtPath: encryptedOutputPath, append: true) else {
            throw NetworkFacadeError.FailedToOpenEncryptOutputStream
        }
        let encryptStatus = try await encrypt.start(input: input, output: encryptedOutputStream, config: EncryptConfig(key: fileKey, iv: iv))
        
        if encryptStatus != EncryptResultStatus.Success {
            throw NetworkFacadeError.EncryptionFailed
        }
        
        let encryptedFileSize = URL(fileURLWithPath: encryptedOutputPath).fileSize
        
        if fileSize != encryptedFileSize {
            throw NetworkFacadeError.EncryptedFileNotSameSizeAsOriginal
        }
        
        return try await upload.start(index: index, bucketId: bucketId, mnemonic: mnemonic, filepath: encryptedOutputPath)
    }
}
