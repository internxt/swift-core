//
//  UploadMultipart.swift
//
//
//  Created by Robert Garcia on 15/11/23.
//

import Foundation


enum UploadMultipartError: Error {
    case CannotOpenInputStream
    case MorePartsThanUploadUrls
}

public struct UploadedPartConfig {
    let hash: Data
    let uuid: String
}

@available(macOS 10.15, *)
extension UploadMultipart: URLSessionTaskDelegate {
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

let PART_SIZE: Double = 30 * 1024 * 1024

@available(macOS 10.15, *)
public class UploadMultipart: NSObject {
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
    
    func start(bucketId: String, fileSize: Int, parts: Int) async throws -> StartUploadResult {
        
        let startUploadResponse = try await networkAPI.startUpload(bucketId: bucketId, uploadSize: fileSize, parts: parts)
        
        guard let startUploadResult  = startUploadResponse.uploads.first else {
            throw UploadError.MissingUploadUrl
        }
        return startUploadResult
    }
    
    func uploadPart(encryptedChunk: Data, uploadUrl: String, partIndex: Int, progressHandler: @escaping ProgressHandler) async throws -> Void {
        
        // Upload the chunk to the given URL
        let successUpload = try await self.uploadEncryptedChunk(encryptedChunk: encryptedChunk, uploadUrl: uploadUrl, progressHandler: progressHandler)
        
        if successUpload == false {
            throw UploadError.UploadNotSuccessful
        }
        
    }
    
    
    func finishUpload(bucketId: String, uploadedParts: [UploadedPartConfig], index: Data, debug: Bool = false) async throws -> FinishUploadResponse {
        var shards: Array<ShardUploadPayload> = Array()
        
        uploadedParts.forEach{uploadedPart in
            shards.append(ShardUploadPayload(
                hash: uploadedPart.hash.toHexString(),
                uuid: uploadedPart.uuid
            ))
        }
        
        let finishUploadResult = try await networkAPI.finishUpload(
            bucketId: bucketId,
            payload: FinishUploadPayload(
                index:  index.toHexString(),
                shards: shards
            ),
            debug: debug
        )
        
        return finishUploadResult
    }
    
    
    
    private func uploadEncryptedChunk(encryptedChunk: Data, uploadUrl: String, progressHandler: ProgressHandler?) async throws -> Bool {
        return try await withCheckedThrowingContinuation { (continuation) in
            var request = URLRequest(
                url: URL(string: uploadUrl)!,
                cachePolicy: .reloadIgnoringLocalCacheData
            )
            
            
            request.httpMethod = "PUT"
            
            let task = urlSession.uploadTask(
                with: request,
                from: encryptedChunk,
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