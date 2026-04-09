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
    let etag: String
    let partNumber: Int
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


@available(macOS 10.15, *)
public class UploadMultipart: NSObject {
    private let encrypt = Encrypt()
    private let cryptoUtils = CryptoUtils()
    private let fileManager = FileManager.default
    private let networkAPI: NetworkAPI
    private let reduceBandwidth: Bool
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        if reduceBandwidth {
            config.httpMaximumConnectionsPerHost = 1
        }
        return URLSession(
            configuration: config,
            delegate: self,
            delegateQueue: .main
        )
    }()
    
    
    
    private var progressHandlersByTaskID = [Int : ProgressHandler]()
    private let progressHandlerStore = ProgressHandlerStore()
    init(networkAPI: NetworkAPI, urlSession: URLSession? = nil, reduceBandwidth: Bool = false) {
        self.networkAPI = networkAPI
        self.reduceBandwidth = reduceBandwidth
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
    
    func uploadPart(encryptedChunk: Data, uploadUrl: String, partIndex: Int, progressHandler: @escaping ProgressHandler) async throws -> String {
        
        // Upload the chunk to the given URL
        let uploadEtag = try await self.uploadEncryptedChunk(encryptedChunk: encryptedChunk, uploadUrl: uploadUrl, progressHandler: progressHandler)
        

        return uploadEtag        
    }
    
    
    func finishUpload(bucketId: String, fileHash: String, uploadUuid: String,uploadId: String, uploadedParts: [UploadedPartConfig], index: Data, debug: Bool = false) async throws -> FinishUploadResponse {
        
        
        var shards: Array<ShardUploadPayload> = Array()
        
        let sortedParts = uploadedParts
            .map { uploadedPart in
                ShardPartPayload(
                    ETag: uploadedPart.etag,
                    PartNumber: uploadedPart.partNumber
                )
            }
            .sorted { $0.PartNumber < $1.PartNumber }

        let shardPayload = ShardUploadPayload(
            hash: fileHash,
            uuid: uploadUuid,
            parts: sortedParts,
            uploadId: uploadId
        )
        
        shards.append(shardPayload)
        
        
        let payload = try FinishUploadPayload(
            index:  index.toHexString(),
            shards: shards
        )
                
        let finishUploadResult = try await networkAPI.finishUpload(
            bucketId: bucketId,
            payload: payload,
            debug: debug
        )
        
        return finishUploadResult
    }
    
    
    
    private func uploadEncryptedChunk(encryptedChunk: Data, uploadUrl: String, progressHandler: ProgressHandler?) async throws -> String {
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
                            guard let etagValue = response?.value(forHTTPHeaderField: "Etag") else {
                                return continuation.resume(with: .failure(UploadError.MissingEtag))
                            }
                            return continuation.resume(with: .success(etagValue))
                        }
                        
                    }
                    
                    continuation.resume(throwing: error)
                }
            )
                        
            Task {
                await progressHandlerStore.setHandler(for: task.taskIdentifier, handler: progressHandler)
            }
            
            
            task.resume()
        }
    }
    
    
    
}

actor ProgressHandlerStore {
    private var handlers: [Int: ProgressHandler] = [:]
    
    func setHandler(for taskID: Int, handler: ProgressHandler?) {
        if let handler = handler {
            handlers[taskID] = handler
        }
    }
    
    func getHandler(for taskID: Int) -> ProgressHandler? {
        return handlers[taskID]
    }
    
    func removeHandler(for taskID: Int) {
        handlers.removeValue(forKey: taskID)
    }
}

