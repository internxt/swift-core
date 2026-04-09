//
//  File.swift
//
//
//  Created by Robert Garcia on 4/8/23.
//

import Foundation
import CryptoKit

let MULTIPART_MIN_SIZE = 100 * 1024 * 1024;
let MULTIPART_CHUNK_SIZE = 50 * 1024 * 1024;
let MAX_WAIT_TIME: TimeInterval = 3600
let THROTTLE_BYTES_PER_SECOND = 5 * 1024 * 1024


@available(macOS 10.15, *)
public struct NetworkFacade {
    private let encrypt: Encrypt = Encrypt()
    private let decrypt: Decrypt = Decrypt()
    private let cryptoUtils: CryptoUtils = CryptoUtils()
    private let mnemonic: String
    private let upload: Upload
    private let uploadMultipart: UploadMultipart
    private let download: Download
    private let reduceBandwidth: Bool
    
    public init(mnemonic: String, networkAPI: NetworkAPI, urlSession: URLSession? = nil, reduceBandwidth: Bool = false, debug: Bool = false){
        self.mnemonic = mnemonic
        self.reduceBandwidth = reduceBandwidth
        self.upload = Upload(networkAPI: networkAPI, urlSession: urlSession, reduceBandwidth: reduceBandwidth)
        self.uploadMultipart = UploadMultipart(networkAPI: networkAPI, urlSession: urlSession, reduceBandwidth: reduceBandwidth)
        self.download = Download(networkAPI: networkAPI, urlSession: urlSession, reduceBandwidth: reduceBandwidth)
    }
    
    public func uploadFile(
        input: InputStream,
        encryptedOutput: URL,
        fileSize: Int,
        bucketId: String,
        progressHandler: @escaping ProgressHandler,
        debug: Bool = false
    ) async throws -> FinishUploadResponse {
        // Generate random index, IV and fileKey
        guard let index = cryptoUtils.getRandomBytes(32) else {
            throw EnrichedError(
                code: .uploadInvalidIndex,
                step: .uploadEncrypt,
                context: ["file_size": String(fileSize)],
                cause: UploadError.InvalidIndex
            )
        }
        
        let iv = Array(index.prefix(16))
        
        let fileKey = try encrypt.generateFileKey(mnemonic: mnemonic, bucketId: bucketId, index: index)
        
        let shouldUseMultipart = fileSize >= MULTIPART_MIN_SIZE
        
        if(shouldUseMultipart) {
            return try await self.runMultipartUpload(
                input: input,
                fileSize: fileSize,
                index: index,
                fileKey: fileKey,
                iv: iv,
                bucketId: bucketId,
                progressHandler: progressHandler,
                debug: debug
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
        progressHandler: @escaping ProgressHandler,
        debug: Bool = false
    ) async throws -> FinishUploadResponse {
        guard let encryptedOutputStream = OutputStream(url: encryptedOutput, append: true) else {
            throw EnrichedError(
                code: .encryptionStreamFailed,
                step: .uploadEncrypt,
                context: [
                    "file_size": String(fileSize),
                    "output_path": encryptedOutput.path
                ],
                cause: NetworkFacadeError.FailedToOpenEncryptOutputStream
            )
        }
        let encryptStatus = try await encrypt.start(input: input, output: encryptedOutputStream, config: EncryptConfig(key: fileKey, iv: iv))
        
        if encryptStatus != EncryptResultStatus.Success {
            throw EnrichedError(
                code: .encryptionFailed,
                step: .uploadEncrypt,
                context: ["file_size": String(fileSize)],
                cause: NetworkFacadeError.EncryptionFailed
            )
        }
        
        let encryptedFileSize = encryptedOutput.fileSize
        if fileSize != encryptedFileSize {
            throw EnrichedError(
                code: .encryptionSizeMismatch,
                step: .uploadEncrypt,
                context: [
                    "original_size": String(fileSize),
                    "encrypted_size": String(encryptedFileSize)
                ],
                cause: NetworkFacadeError.EncryptedFileNotSameSizeAsOriginal
            )
        }
        
        let result = try await upload.start(index: index, bucketId: bucketId, mnemonic: mnemonic, encryptedFileURL: encryptedOutput, progressHandler: progressHandler)
        
      
        if reduceBandwidth {
            let targetTime = Double(fileSize) / Double(THROTTLE_BYTES_PER_SECOND)
            let delay = max(0, targetTime * 0.3) // 30% extra delay to bring speed down
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        return result
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
        var hasher = SHA256.init()
        let parts = ceil(Double(fileSize) / Double(MULTIPART_CHUNK_SIZE))
        let maxProgressPerPart: Double = 0.99 / parts
        
        let startUploadResult: StartUploadResult
        do {
            startUploadResult = try await uploadMultipart.start(bucketId: bucketId, fileSize: fileSize, parts: Int(parts))
        } catch {
            throw EnrichedError(
                code: .uploadStartFailed,
                step: .uploadMultipartStart,
                context: [
                    "bucket_id": bucketId,
                    "file_size": String(fileSize),
                    "parts": String(Int(parts))
                ],
                cause: error
            )
        }
        
        guard let uploadUrls = startUploadResult.urls else {
            throw EnrichedError(
                code: .uploadMissingUrl,
                step: .uploadMultipartStart,
                context: [
                    "bucket_id": bucketId,
                    "upload_uuid": startUploadResult.uuid
                ],
                cause: UploadError.MissingUploadUrl
            )
        }
        
        if uploadUrls.count != Int(parts) {
            throw EnrichedError(
                code: .uploadMissingUrl,
                step: .uploadMultipartStart,
                context: [
                    "expected_parts": String(Int(parts)),
                    "received_urls": String(uploadUrls.count)
                ],
                cause: UploadMultipartError.MorePartsThanUploadUrls
            )
        }
        
        
        let uploadedPartsActor = UploadedPartsActor()
        let uploadState = UploadState()
        
        input.open()
        defer { input.close() }
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = self.reduceBandwidth ? 1 : 6

        var partIndex = 0
        try await encrypt.encryptFileIntoChunks(
            chunkSizeInBytes: MULTIPART_CHUNK_SIZE,
            totalBytes: fileSize,
            inputStream: input,
            key: fileKey,
            iv: iv
        ) { encryptedChunk in
            guard await !uploadState.isAborted() else {
                throw UploadError.UploadNotSuccessful
            }

            hasher.update(data: encryptedChunk)

            let uploadUrl = uploadUrls[partIndex]
            let operation = UploadPartOperation(
                encryptedChunk: encryptedChunk,
                partIndex: partIndex,
                uploadUrl: uploadUrl,
                uploadMultipart: uploadMultipart,
                uploadState: uploadState,
                maxProgressPerPart: maxProgressPerPart,
                progressHandler: { _ in },
                uploadedPartsActor: uploadedPartsActor,
                targetBytesPerSecond: self.reduceBandwidth ? THROTTLE_BYTES_PER_SECOND : nil
            )

            operation.completionBlock = {
                operation.clearMemory()
                Task {
                    
                    let partsUploaded = await uploadedPartsActor.getUploadedPartsConfigs()
                    let completedParts = partsUploaded.count
                    let progress = Double(completedParts) / Double(parts) * 0.99
                    progressHandler(progress)
                }
                
            }

            // Wait until the number of active operations is below the concurrency limit
            while operationQueue.operationCount >= operationQueue.maxConcurrentOperationCount {
                await Task.sleep(UInt64(100_000_000))
            }

            operationQueue.addOperation(operation)
            partIndex += 1
        }
        
        operationQueue.waitUntilAllOperationsAreFinished()
        
        if await uploadState.isAborted() {
            operationQueue.cancelAllOperations()
            throw UploadError.UploadNotSuccessful
        }
        
        let fileSHA256digest = hasher.finalize()
        var sha256Hash = [UInt8]()
        fileSHA256digest.withUnsafeBytes { bytes in
            sha256Hash.append(contentsOf: bytes)
        }
        
        let fileHash = HMAC().ripemd160(message: Data(sha256Hash))
        
        let finishUpload = try await uploadMultipart.finishUpload(
            bucketId: bucketId,
            fileHash: fileHash.toHexString(),
            uploadUuid: startUploadResult.uuid,
            uploadId: startUploadResult.UploadId!,
            uploadedParts: await uploadedPartsActor.getUploadedPartsConfigs(),
            index: Data(index),
            debug: debug
        )
        
        progressHandler(1)
        return finishUpload
    }
    
    actor UploadedPartsActor {
        private var uploadedPartsConfigs: [UploadedPartConfig] = []
        
        
        func addUploadedPartConfig(_ partConfig: UploadedPartConfig) {
            uploadedPartsConfigs.append(partConfig)
        }

        func getUploadedPartsConfigs() -> [UploadedPartConfig] {
            return uploadedPartsConfigs
        }
        
        func isPartUploaded(partIndex: Int) -> Bool {
            return uploadedPartsConfigs.contains(where: { $0.partNumber == partIndex + 1 })
        }
    }
    
    actor UploadState {
        var uploadAborted = false
        
        func setAborted() {
            uploadAborted = true
        }
        
        func isAborted() -> Bool {
            return uploadAborted
        }
    }
    
    public func downloadFile(bucketId: String, fileId: String, encryptedFileDestination: URL, destinationURL: URL, progressHandler: @escaping ProgressHandler, debug: Bool = false) async throws -> URL {
        
        func downloadProgressHandler(downloadProgress: Double) {
            let downloadMaxProgress = 0.9;
            // We need to wait for the decryption, so download reachs downloadMaxProgress, and not 100%
            progressHandler(downloadProgress * downloadMaxProgress)
            
        }
        
        let encryptedFileDownloadResult = try await download.start(
            bucketId:bucketId,
            fileId: fileId,
            destination: encryptedFileDestination,
            progressHandler: downloadProgressHandler,
            debug: debug
        )
        
        
        let decryptedFileURL = try await decryptFile(
            bucketId: bucketId,
            destinationURL: destinationURL,
            progressHandler: progressHandler,
            encryptedFileDownloadResult: encryptedFileDownloadResult
        )
        
        
        return decryptedFileURL
    }
    
    public func decryptFile(bucketId: String, destinationURL: URL, progressHandler: ProgressHandler, encryptedFileDownloadResult: DownloadResult, ignoreHashMissmatchCheck: Bool = false) async throws -> URL {
        
        if encryptedFileDownloadResult.url.fileSize == 0 {
            throw EnrichedError(
                code: .downloadFileEmpty,
                step: .downloadDecrypt,
                context: [
                    "bucket_id": bucketId,
                    "file_path": encryptedFileDownloadResult.url.path
                ],
                cause: NetworkFacadeError.FileIsEmpty
            )
        }
        
        let fullHexString = encryptedFileDownloadResult.index
        let hexIv = fullHexString.prefix(upTo: fullHexString.index(fullHexString.startIndex, offsetBy: 32))
        let iv = cryptoUtils.hexStringToBytes(String(hexIv))
        let fileKey = try encrypt.generateFileKey(mnemonic: mnemonic, bucketId: bucketId, index: cryptoUtils.hexStringToBytes(encryptedFileDownloadResult.index))
        
        guard let hashInputStream = InputStream(url: encryptedFileDownloadResult.url) else {
            throw EnrichedError(
                code: .decryptionStreamFailed,
                step: .downloadDecrypt,
                context: [
                    "bucket_id": bucketId,
                    "file_path": encryptedFileDownloadResult.url.path
                ],
                cause: NetworkFacadeError.FailedToOpenDecryptInputStream
            )
        }
        
        let encryptedContentHash = encrypt.getFileContentHash(stream: hashInputStream)
        
        
        let hashMatch = encryptedContentHash.toHexString() == encryptedFileDownloadResult.expectedContentHash
        if hashMatch == false && ignoreHashMissmatchCheck != false {
            throw EnrichedError(
                code: .downloadHashMismatch,
                step: .downloadDecrypt,
                context: [
                    "expected_hash": encryptedFileDownloadResult.expectedContentHash ?? "unknown",
                    "actual_hash": encryptedContentHash.toHexString()
                ],
                cause: NetworkFacadeError.HashMissmatch
            )
        }
        
        
        guard let encryptedInputStream = InputStream(url: encryptedFileDownloadResult.url) else {
            throw EnrichedError(
                code: .decryptionStreamFailed,
                step: .downloadDecrypt,
                context: ["file_path": encryptedFileDownloadResult.url.path],
                cause: NetworkFacadeError.FailedToOpenDecryptInputStream
            )
        }
        
        
        
        guard let plainOutputStream = OutputStream(url: destinationURL, append: false) else {
            throw EnrichedError(
                code: .decryptionStreamFailed,
                step: .downloadDecrypt,
                context: ["destination_path": destinationURL.path],
                cause: NetworkFacadeError.FailedToOpenDecryptOutputStream
            )
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
            throw EnrichedError(
                code: .decryptionFailed,
                step: .downloadDecrypt,
                context: ["bucket_id": bucketId],
                cause: NetworkFacadeError.DecryptionFailed
            )
        }
    }
    
    class UploadPartOperation: AsyncOperation {
        var encryptedChunk: Data?
        let partIndex: Int
        let uploadUrl: String
        let uploadMultipart: UploadMultipart
        let uploadState: UploadState
        let maxProgressPerPart: Double
        let progressHandler: (Double) -> Void
        let uploadedPartsActor: UploadedPartsActor
        let targetBytesPerSecond: Int?
        
        init(
            encryptedChunk: Data,
            partIndex: Int,
            uploadUrl: String,
            uploadMultipart: UploadMultipart,
            uploadState: UploadState,
            maxProgressPerPart: Double,
            progressHandler: @escaping (Double) -> Void,
            uploadedPartsActor: UploadedPartsActor,
            targetBytesPerSecond: Int? = nil
        ) {
            self.encryptedChunk = encryptedChunk
            self.partIndex = partIndex
            self.uploadUrl = uploadUrl
            self.uploadMultipart = uploadMultipart
            self.uploadState = uploadState
            self.maxProgressPerPart = maxProgressPerPart
            self.progressHandler = progressHandler
            self.uploadedPartsActor = uploadedPartsActor
            self.targetBytesPerSecond = targetBytesPerSecond
        }
        
        override func main() {
            Task {
                do {
                    let chunkSize = encryptedChunk?.count ?? 0
                    let startTime = CFAbsoluteTimeGetCurrent()
                    
                    try await uploadPartWithRetry()
                    if let target = targetBytesPerSecond, chunkSize > 0 {
                        let targetTime = Double(chunkSize) / Double(target)
                        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
                        if elapsed < targetTime {
                            let delay = targetTime - elapsed
                            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        }
                    }
                    
                    completeOperation()
                } catch {
                    await uploadState.setAborted()
                    completeOperation()
                }
            }
        }
        
        private func uploadPartWithRetry() async throws {
            var attempt = 0
            let maxRetries = 3

            while attempt < maxRetries {
                if await uploadState.isAborted() {
                    throw UploadError.UploadNotSuccessful
                }

                do {
                  
                    if !NetworkMonitor.shared.isConnected {
                        let startTime = Date()

                        while !NetworkMonitor.shared.isConnected {
                            try await Task.sleep(nanoseconds: 20 * 1_000_000_000) // Check every 20 seconds
                            if Date().timeIntervalSince(startTime) > MAX_WAIT_TIME {
                                await uploadState.setAborted()
                                throw UploadError.UploadNotSuccessful
                            }
                        }
                    }
                    guard let chunk = encryptedChunk else {
                        throw UploadError.MissingChunk
                    }
                    let etag = try await uploadMultipart.uploadPart(
                        encryptedChunk: chunk,
                        uploadUrl: uploadUrl,
                        partIndex: partIndex
                    ) { progress in
                        self.progressHandler(progress * self.maxProgressPerPart / 100)
                    }

                    let uploadedPartConfig = UploadedPartConfig(etag: etag, partNumber: partIndex + 1)
                    await uploadedPartsActor.addUploadedPartConfig(uploadedPartConfig)
                    return
                }
                catch {
                    if let urlError = error as? URLError,
                           urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost  {
                    }else {
                        
                        attempt += 1
                        if attempt >= maxRetries {
                            await uploadState.setAborted()
                            throw UploadError.PartUploadFailed(partIndex: partIndex, error: error)
                        }
                    }

                }
            }
        }
        
        func clearMemory() {
            encryptedChunk = nil
        }
    }

}
