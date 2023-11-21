//
//  File.swift
//  
//
//  Created by Robert Garcia on 4/8/23.
//

import Foundation

public typealias Percentage = Double
public typealias ProgressHandler = (Percentage) -> Void


@available(macOS 10.15, *)
extension Upload: URLSessionTaskDelegate {
    public func urlSession(
            _ session: URLSession,
            task: URLSessionTask,
            didSendBodyData bytesSent: Int64,
            totalBytesSent: Int64,
            totalBytesExpectedToSend: Int64
    ) {
            let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
            let handler = progressHandlersByTaskID[task.taskIdentifier]
            handler?(progress)
    }
}


@available(macOS 10.15, *)
public class Upload: NSObject  {
    private let encrypt = Encrypt()
    private let cryptoUtils = CryptoUtils()
    private let fileManager = FileManager.default
    private let networkAPI: NetworkAPI
    private lazy var urlSession = URLSession(
           configuration: .default,
           delegate: self,
           delegateQueue: .main
       )
    
    private var progressHandlersByTaskID = [Int : ProgressHandler]()

    init(networkAPI: NetworkAPI, urlSession: URLSession? = nil) {
        self.networkAPI = networkAPI
        super.init()
        if urlSession != nil {
            self.urlSession = urlSession!
        }
    }
    
    private func needsMultipart() -> Bool {
        return true
    }
    func start(index: [UInt8], bucketId: String, mnemonic: String, encryptedFileURL: URL, debug: Bool = false, progressHandler: ProgressHandler? = nil) async throws -> FinishUploadResponse {
        let source = encryptedFileURL
         
        let fileSize = source.fileSize
    
        if self.needsMultipart() {
            //return try await UploadMultipart(networkAPI: self.networkAPI).start(index: index, bucketId: bucketId, mnemonic: mnemonic, encryptedFileURL: encryptedFileURL, progressHandler: progressHandler)
        }
        guard let hashInputStream = InputStream(url: encryptedFileURL) else {
            throw UploadError.CannotGenerateFileHash
        }
        
        let fileHash = encrypt.getFileContentHash(stream: hashInputStream)
        var uploadStart: StartUploadResponse
        
        do {
             uploadStart = try await networkAPI.startUpload(bucketId: bucketId, uploadSize: Int(fileSize), debug: debug)
        } catch {
            
            guard let apiError = error as? APIClientError else {
                throw StartUploadError(apiError: nil)
            }
            
            throw StartUploadError(apiError: apiError)
        }
        
        
        guard let uploadResult = uploadStart.uploads.first else {
            throw UploadError.MissingUploadUrl
        }
        guard let uploadUrl = uploadResult.url else {
            throw UploadError.MissingUploadUrl
        }
        
        let successUpload = try await self.uploadEncryptedFile(uploadUrl: uploadUrl, encryptedFile: source, progressHandler: progressHandler)
        
        if successUpload == false {
            throw UploadError.UploadNotSuccessful
        }
        
        var shards: Array<ShardUploadPayload> = Array()
        shards.append(ShardUploadPayload(
            hash: cryptoUtils.bytesToHexString(Array(fileHash)),
            uuid: uploadResult.uuid
        ))
        let finishUploadResult = try await networkAPI.finishUpload(bucketId: bucketId, payload: FinishUploadPayload(
                index:  cryptoUtils.bytesToHexString(index),
                shards: shards
            )
        )
        
        if finishUploadResult.size != Int(fileSize) {
            throw UploadError.UploadedSizeNotMatching
        }
        
        
        return finishUploadResult
    }
    
    
    private func uploadEncryptedFile(uploadUrl: String, encryptedFile: URL, progressHandler: ProgressHandler? = nil) async throws -> Bool {
        return try await withCheckedThrowingContinuation { (continuation) in
            var request = URLRequest(
                url: URL(string: uploadUrl)!,
                cachePolicy: .reloadIgnoringLocalCacheData
            )
            
            
            request.httpMethod = "PUT"
            
            let task = urlSession.uploadTask(
                with: request,
                fromFile: encryptedFile,
                completionHandler: { data, res, error in
                    guard let error = error else {
                        let response = res as? HTTPURLResponse
                        if response?.statusCode != 200 {
                            return continuation.resume(with: .failure(UploadError.UploadNotSuccessful))
                        } else {
                            return continuation.resume(with: .success(true))
                        }
                        
                    }
                    
                    continuation.resume(throwing: error)
                }
            )
            
            if progressHandler != nil {
                progressHandlersByTaskID[task.taskIdentifier] = progressHandler
            }
            
            
            task.resume()
        }
    }
    
    
}

