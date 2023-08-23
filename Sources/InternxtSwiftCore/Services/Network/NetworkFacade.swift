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
    private let decrypt: Decrypt = Decrypt()
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
    
    public func downloadFile(bucketId: String, fileId: String, encryptedFileDestination: URL, destinationURL: URL, progressHandler: @escaping ProgressHandler) async throws -> URL {
        guard let index = cryptoUtils.getRandomBytes(32) else {
            throw UploadError.InvalidIndex
        }
        
        let fullHexString = cryptoUtils.bytesToHexString(index)
        let hexIv = fullHexString.prefix(upTo: fullHexString.index(fullHexString.startIndex, offsetBy: 32))
        let iv = cryptoUtils.hexStringToBytes(String(hexIv))
        
        func downloadProgressHandler(downloadProgress: Double) {
            let downloadMaxProgress = 0.9;
            // We need to wait for the decryption, so download reachs downloadMaxProgress, and not 100%
            progressHandler(downloadProgress * downloadMaxProgress)
            
        }
        let fileKey = try encrypt.generateFileKey(mnemonic: mnemonic, bucketId: bucketId, index: index)
        
        let encryptedFileDownloadResult = try await download.start(
            bucketId:bucketId,
            fileId: fileId,
            destination: encryptedFileDestination,
            progressHandler: downloadProgressHandler
        )
        
        
        print("Download result")
        print(encryptedFileDownloadResult)
        
        
        guard let hashInputStream = InputStream(url: encryptedFileDownloadResult.url) else {
            throw NetworkFacadeError.FailedToOpenDecryptInputStream
        }
        
        let encryptedContentHash = encrypt.getFileContentHash(stream: hashInputStream)
        
        let hashMatch = encryptedContentHash.toHexString() == encryptedFileDownloadResult.expectedContentHash
        if hashMatch == false {
            throw NetworkFacadeError.HashMissmatch
        }
        
       
        guard let encryptedInputStream = InputStream(url: encryptedFileDownloadResult.url) else {
            throw NetworkFacadeError.FailedToOpenDecryptInputStream
        }
        
        guard let plainOutputStream = OutputStream(url: destinationURL, append: false) else {
            throw NetworkFacadeError.FailedToOpenDecryptOutputStream
        }
        
        let decryptResult = try await decrypt.start(
            input: encryptedInputStream,
            output: plainOutputStream,
            config: DecryptConfig(key: fileKey, iv: iv)
        )
        
        // Reach 100%
        progressHandler(1)
        
        if decryptResult == .Success {
            return destinationURL
        } else {
            throw NetworkFacadeError.DecryptionFailed
        }
        
    }
}
