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

    init(networkAPI: NetworkAPI, urlSession: URLSession? = nil, reduceBandwidth: Bool = false) {
        self.networkAPI = networkAPI
        self.reduceBandwidth = reduceBandwidth
        super.init()
        if urlSession != nil {
            self.urlSession = urlSession!
        }
    }
    
   
    func start(index: [UInt8], bucketId: String, mnemonic: String, encryptedFileURL: URL, progressHandler: ProgressHandler? = nil, debug: Bool = false) async throws -> FinishUploadResponse {
        let source = encryptedFileURL
         
        let fileSize = source.fileSize
    
        
        guard let hashInputStream = InputStream(url: encryptedFileURL) else {
            throw EnrichedError(
                code: .uploadCannotGenerateHash,
                step: .uploadStart,
                context: ["file_path": encryptedFileURL.path],
                cause: UploadError.CannotGenerateFileHash
            )
        }
        
        let fileHash = encrypt.getFileContentHash(stream: hashInputStream)
        var uploadStart: StartUploadResponse
        
        do {
             uploadStart = try await networkAPI.startUpload(bucketId: bucketId, uploadSize: Int(fileSize), debug: debug)
        } catch {
            let errorCode: ErrorCode
            var context: [String: String] = [
                "bucket_id": bucketId,
                "file_size": String(fileSize)
            ]
            
            if let apiError = error as? APIClientError {
                context["status_code"] = String(apiError.statusCode)
                context["api_message"] = apiError.message
                
                switch apiError.statusCode {
                case 401: errorCode = .apiUnauthorized
                case 402: errorCode = .apiPaymentRequired
                case 404: errorCode = .apiNotFound
                case 500...599: errorCode = .apiServerError
                default: errorCode = .uploadStartFailed
                }
            } else if let urlError = error as? URLError {
                context["url_error_code"] = String(urlError.code.rawValue)
                switch urlError.code {
                case .timedOut: errorCode = .networkTimeout
                case .notConnectedToInternet: errorCode = .networkNoConnection
                case .networkConnectionLost: errorCode = .networkConnectionLost
                case .cannotConnectToHost: errorCode = .networkCannotConnect
                default: errorCode = .uploadStartFailed
                }
            } else {
                errorCode = .uploadStartFailed
            }
            
            throw EnrichedError(
                code: errorCode,
                step: .uploadStart,
                context: context,
                cause: error
            )
        }
        
        
        guard let uploadResult = uploadStart.uploads.first else {
            throw EnrichedError(
                code: .uploadMissingUrl,
                step: .uploadStart,
                context: ["bucket_id": bucketId],
                cause: UploadError.MissingUploadUrl
            )
        }
        
        guard let uploadUrl = uploadResult.url else {
            throw EnrichedError(
                code: .uploadMissingUrl,
                step: .uploadStart,
                context: ["bucket_id": bucketId, "upload_uuid": uploadResult.uuid],
                cause: UploadError.MissingUploadUrl
            )
        }
        
        do {
            let successUpload = try await self.uploadEncryptedFile(uploadUrl: uploadUrl, encryptedFile: source, progressHandler: progressHandler)
            
            if successUpload == false {
                throw EnrichedError(
                    code: .uploadS3Failed,
                    step: .uploadToS3,
                    context: [
                        "file_size": String(fileSize)
                    ],
                    cause: UploadError.UploadNotSuccessful
                )
            }
        } catch let enrichedError as EnrichedError {
            throw enrichedError
        } catch {
            let errorCode: ErrorCode
            var context: [String: String] = [
                "file_size": String(fileSize)
            ]
            
            if let urlError = error as? URLError {
                context["url_error_code"] = String(urlError.code.rawValue)
                switch urlError.code {
                case .timedOut: errorCode = .uploadS3Timeout
                case .notConnectedToInternet: errorCode = .networkNoConnection
                case .networkConnectionLost: errorCode = .networkConnectionLost
                case .cannotConnectToHost: errorCode = .networkCannotConnect
                default: errorCode = .uploadS3Failed
                }
            } else {
                errorCode = .uploadS3Failed
            }
            
            throw EnrichedError(
                code: errorCode,
                step: .uploadToS3,
                context: context,
                cause: error
            )
        }
        
        var shards: Array<ShardUploadPayload> = Array()
        shards.append(ShardUploadPayload(
            hash: cryptoUtils.bytesToHexString(Array(fileHash)),
            uuid: uploadResult.uuid,
            parts: nil
        ))
        
        let finishUploadResult: FinishUploadResponse
        do {
            finishUploadResult = try await networkAPI.finishUpload(bucketId: bucketId, payload: FinishUploadPayload(
                    index:  cryptoUtils.bytesToHexString(index),
                    shards: shards
                )
            )
        } catch {
            let errorCode: ErrorCode
            var context: [String: String] = [
                "bucket_id": bucketId,
                "upload_uuid": uploadResult.uuid
            ]
            
            if let apiError = error as? APIClientError {
                context["status_code"] = String(apiError.statusCode)
                context["api_message"] = apiError.message
                errorCode = .uploadFinishFailed
            } else if let urlError = error as? URLError {
                context["url_error_code"] = String(urlError.code.rawValue)
                switch urlError.code {
                case .timedOut: errorCode = .networkTimeout
                case .notConnectedToInternet: errorCode = .networkNoConnection
                case .networkConnectionLost: errorCode = .networkConnectionLost
                default: errorCode = .uploadFinishFailed
                }
            } else {
                errorCode = .uploadFinishFailed
            }
            
            throw EnrichedError(
                code: errorCode,
                step: .uploadFinish,
                context: context,
                cause: error
            )
        }
        
        if finishUploadResult.size != Int(fileSize) {
            throw EnrichedError(
                code: .uploadSizeMismatch,
                step: .uploadFinish,
                context: [
                    "expected_size": String(fileSize),
                    "actual_size": String(finishUploadResult.size)
                ],
                cause: UploadError.UploadedSizeNotMatching
            )
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

