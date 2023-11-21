//
//  File.swift
//
//
//  Created by Robert Garcia on 4/8/23.
//

import Foundation

let MULTIPART_MIN_SIZE = 100 * 1024 * 1024;
let MULTIPART_CHUNK_SIZE = 100 * 1024 * 1024;

@available(macOS 10.15, *)
public struct NetworkFacade {
    private let encrypt: Encrypt = Encrypt()
    private let decrypt: Decrypt = Decrypt()
    private let cryptoUtils: CryptoUtils = CryptoUtils()
    private let mnemonic: String
    private let upload: Upload
    private let uploadMultipart: UploadMultipart
    private let download: Download
    
    public init(mnemonic: String, networkAPI: NetworkAPI, urlSession: URLSession? = nil, debug: Bool = false){
        self.mnemonic = mnemonic
        self.upload = Upload(networkAPI: networkAPI, urlSession: urlSession)
        self.uploadMultipart = UploadMultipart(networkAPI: networkAPI, urlSession: urlSession)
        self.download = Download(networkAPI: networkAPI, urlSession: urlSession)
    }
    
    public func uploadFile(
        input: InputStream,
        encryptedOutput: URL,
        fileSize: Int,
        bucketId: String,
        progressHandler: @escaping ProgressHandler
    ) async throws -> FinishUploadResponse {
        // Generate random index, IV and fileKey
        guard let index = cryptoUtils.getRandomBytes(32) else {
            throw UploadError.InvalidIndex
        }
        
        let iv = Array(index.prefix(16))
        
        let fileKey = try encrypt.generateFileKey(mnemonic: mnemonic, bucketId: bucketId, index: index)
        
        let shouldUseMultipart = fileSize >= MULTIPART_MIN_SIZE
        
        if(shouldUseMultipart) {
            print("MULTIPART IS NEEDED, GOING FOR IT")
            return try await self.runMultipartUpload(
                input: input,
                fileSize: fileSize,
                index: index,
                fileKey: fileKey,
                iv: iv,
                bucketId: bucketId,
                progressHandler: progressHandler
            )
        }
        
        return try await self.runSingleFileUpload(
            input: input,
            encryptedOutput: encryptedOutput,
            fileSize: fileSize,
            index: index,
            fileKey: fileKey,
            iv: iv,
            bucketId: bucketId,
            progressHandler: progressHandler
        )
    }
    
    private func runSingleFileUpload(
        input: InputStream,
        encryptedOutput: URL,
        fileSize: Int,
        index: [UInt8],
        fileKey: [UInt8],
        iv: [UInt8],
        bucketId: String,
        progressHandler: @escaping ProgressHandler
    ) async throws -> FinishUploadResponse {
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
    
    private func runMultipartUpload(
        input: InputStream,
        fileSize: Int,
        index: [UInt8],
        fileKey: [UInt8],
        iv: [UInt8],
        bucketId: String,
        progressHandler: @escaping ProgressHandler,
        debug: Bool = false
    ) async throws -> FinishUploadResponse {
        
        let parts = 3
        
        print("File will be broken into \(Double(fileSize / MULTIPART_CHUNK_SIZE)) parts")
        
        var partIndex = 0
        var uploadedPartsConfigs: [UploadedPartConfig] = []
        let startUploadResult = try await uploadMultipart.start(bucketId: bucketId, fileSize: fileSize, parts: Int(parts))
        guard let uploadUrls = startUploadResult.urls else {
            throw UploadError.MissingUploadUrl
        }
        
        if uploadUrls.count != Int(parts) {
            throw UploadMultipartError.MorePartsThanUploadUrls
        }
        func processEncryptedChunk(encryptedChunk: Data, partIndex: Int, debug: Bool = false) async throws -> Void {
            let hash = encrypt.getFileContentHash(stream: InputStream(data: encryptedChunk))
            
            let uploadUrl = uploadUrls[partIndex]
            try await uploadMultipart.uploadPart(encryptedChunk: encryptedChunk, uploadUrl: uploadUrl, partIndex: partIndex){progress in
                
                //print("UPLOAD PROGRESS FOR PART \(partIndex)", progress)
            }
            let uploadedPartConfig = UploadedPartConfig(
                hash: hash,
                uuid: startUploadResult.uuid
            )
            
            uploadedPartsConfigs.append(uploadedPartConfig)
            
        }
        
        try await encrypt.encryptFileIntoChunks(
            chunkSizeInBytes: MULTIPART_CHUNK_SIZE,
            totalBytes: fileSize,
            inputStream: input,
            key: fileKey,
            iv: iv
        ){encryptedChunk in
            // If something fails here, the error is propagated
            // and the stream reading is stopped
            try await processEncryptedChunk(encryptedChunk: encryptedChunk, partIndex: partIndex)
            print("Chunk number \(partIndex) uploaded")
            
            partIndex += 1
        }
            
        let finishUpload = try await uploadMultipart.finishUpload(bucketId: bucketId, uploadedParts: uploadedPartsConfigs, index: Data(index), debug: debug)
        print("Chunk number \(partIndex) uploaded")
        return finishUpload
    }
    
    public func downloadFile(bucketId: String, fileId: String, encryptedFileDestination: URL, destinationURL: URL, progressHandler: @escaping ProgressHandler) async throws -> URL {
        
        func downloadProgressHandler(downloadProgress: Double) {
            let downloadMaxProgress = 0.9;
            // We need to wait for the decryption, so download reachs downloadMaxProgress, and not 100%
            progressHandler(downloadProgress * downloadMaxProgress)
            
        }
        
        let encryptedFileDownloadResult = try await download.start(
            bucketId:bucketId,
            fileId: fileId,
            destination: encryptedFileDestination,
            progressHandler: downloadProgressHandler
        )
        
        
        let decryptedFileURL = try await decryptFile(
            bucketId: bucketId,
            destinationURL: destinationURL,
            progressHandler: progressHandler,
            encryptedFileDownloadResult: encryptedFileDownloadResult
        )
        
        
        return decryptedFileURL
    }
    
    public func decryptFile(bucketId: String, destinationURL: URL, progressHandler: ProgressHandler, encryptedFileDownloadResult: DownloadResult) async throws -> URL {
        
        if encryptedFileDownloadResult.url.fileSize == 0 {
            throw NetworkFacadeError.FileIsEmpty
        }
        
        let fullHexString = encryptedFileDownloadResult.index
        let hexIv = fullHexString.prefix(upTo: fullHexString.index(fullHexString.startIndex, offsetBy: 32))
        let iv = cryptoUtils.hexStringToBytes(String(hexIv))
        let fileKey = try encrypt.generateFileKey(mnemonic: mnemonic, bucketId: bucketId, index: cryptoUtils.hexStringToBytes(encryptedFileDownloadResult.index))
        
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
