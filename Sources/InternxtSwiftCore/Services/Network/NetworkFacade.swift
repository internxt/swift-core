//
//  File.swift
//  
//
//  Created by Robert Garcia on 4/8/23.
//

import Foundation

@available(macOS 10.15, *)

public struct NetworkFacade {
    private let encrypt: Encrypt = Encrypt()
    private let cryptoUtils: CryptoUtils = CryptoUtils()
    private let mnemonic: String
    private let upload: Upload
    private let download: Download
    
    public init(mnemonic: String, networkAPI: NetworkAPI, urlSession: URLSession? = nil){
        self.mnemonic = mnemonic
        self.upload = Upload(networkAPI: networkAPI, urlSession: urlSession)
        self.download = Download(networkAPI: networkAPI, urlSession: urlSession)
    }
    
    public func uploadFile(input: InputStream, encryptedOutput: URL, fileSize: Int, bucketId: String, progressHandler: @escaping ProgressHandler) async throws -> FinishUploadResponse {
        // Generate random index, IV and fileKey
        guard let index = cryptoUtils.getRandomBytes(32) else {
            throw UploadError.InvalidIndex
        }
        
        let iv = Array(index.prefix(16))
        
        let fileKey = try encrypt.generateFileKey(mnemonic: mnemonic, bucketId: bucketId, index: index)
        
        guard let encryptedOutputStream = OutputStream(url: encryptedOutput, append: true) else {
            throw NetworkFacadeError.FailedToOpenEncryptOutputStream
        }
        let encryptStatus = try await encrypt.start(input: input, output: encryptedOutputStream, config: EncryptConfig(key: fileKey, iv: iv))
        
        if encryptStatus != EncryptResultStatus.Success {
            throw NetworkFacadeError.EncryptionFailed
        }
        
        let encryptedFileSize = encryptedOutput.fileSize
        if fileSize != encryptedFileSize {
            throw NetworkFacadeError.EncryptedFileNotSameSizeAsOriginal
        }
        
        return try await upload.start(index: index, bucketId: bucketId, mnemonic: mnemonic, encryptedFileURL: encryptedOutput, progressHandler: progressHandler)
    }
    
    public func downloadFile(bucketId: String, fileId: String) async throws -> URL {
        return try await download.start(bucketId:bucketId, fileId: fileId)
    }
}
