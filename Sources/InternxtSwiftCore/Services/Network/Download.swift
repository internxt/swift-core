//
//  File.swift
//  
//
//  Created by Robert Garcia on 23/8/23.
//

import Foundation


enum DownloadError: Error {
    case DownloadNotSuccessful
    case MissingDownloadURL
    case MultipartDownloadNotSupported
    case FailedToCopyDownloadedURL
    case InvalidBucketId
    case MissingShards
    case V1DownloadDetected
    case NoMirrorsFound
}

public struct DownloadResult {
    public var url: URL
    public var expectedContentHash: String?
    public var index: String
    init(url: URL, expectedContentHash: String?, index: String) {
        self.url = url
        self.expectedContentHash = expectedContentHash
        self.index = index
    }
}



@available(macOS 10.15, *)
public class Download: NSObject {
    private let networkAPI: NetworkAPI
    
    private var observation: NSKeyValueObservation?

    private var progressHandlersByTaskID = [Int : ProgressHandler]()
    private var urlSession: URLSession
    init(networkAPI: NetworkAPI, urlSession: URLSession?, reduceBandwidth: Bool = false) {
        self.networkAPI = networkAPI
        if let urlSession = urlSession {
            self.urlSession = urlSession
        } else {
            let config = URLSessionConfiguration.ephemeral
            if reduceBandwidth {
                config.httpMaximumConnectionsPerHost = 1
            }
            self.urlSession = URLSession(configuration: config)
        }
        
        super.init()
    }
    
    deinit {
        observation?.invalidate()
    }
    
    
    func start(bucketId: String, fileId: String, destination: URL,  progressHandler: ProgressHandler? = nil,  debug: Bool = false) async throws ->  DownloadResult {
        if bucketId.isValidHex == false {
            throw EnrichedError(
                code: .downloadInvalidBucket,
                step: .downloadGetInfo,
                context: ["bucket_id": bucketId],
                cause: DownloadError.InvalidBucketId
            )
        }
        
        let info: GetFileInfoResponse
        do {
            info = try await networkAPI.getFileInfo(bucketId: bucketId, fileId: fileId, debug: debug)
        } catch let enrichedError as EnrichedError {
            throw enrichedError
        } catch {
            let errorCode: ErrorCode
            var context: [String: String] = [
                "bucket_id": bucketId,
                "file_id": fileId
            ]
            
            if let apiError = error as? APIClientError {
                context["status_code"] = String(apiError.statusCode)
                context["api_message"] = apiError.message
                
                switch apiError.statusCode {
                case 401: errorCode = .apiUnauthorized
                case 404: errorCode = .apiNotFound
                case 500...599: errorCode = .apiServerError
                default: errorCode = .downloadInfoFailed
                }
            } else if let urlError = error as? URLError {
                context["url_error_code"] = String(urlError.code.rawValue)
                switch urlError.code {
                case .timedOut: errorCode = .networkTimeout
                case .notConnectedToInternet: errorCode = .networkNoConnection
                case .networkConnectionLost: errorCode = .networkConnectionLost
                case .cannotConnectToHost: errorCode = .networkCannotConnect
                default: errorCode = .downloadInfoFailed
                }
            } else {
                errorCode = .downloadInfoFailed
            }
            
            throw EnrichedError(
                code: errorCode,
                step: .downloadGetInfo,
                context: context,
                cause: error
            )
        }
        
        let isV1Download = info.version == 1
        
        if isV1Download {
            let mirrors: [FileMirrorShard]
            do {
                mirrors = try await networkAPI.getFileMirrors(bucketId: bucketId, fileId: fileId, debug: debug)
            } catch let enrichedError as EnrichedError {
                throw enrichedError
            } catch {
                var context: [String: String] = [
                    "bucket_id": bucketId,
                    "file_id": fileId
                ]
                if let apiError = error as? APIClientError {
                    context["status_code"] = String(apiError.statusCode)
                    context["api_message"] = apiError.message
                }
                throw EnrichedError(
                    code: .downloadMirrorsFailed,
                    step: .downloadGetUrl,
                    context: context,
                    cause: error
                )
            }
            
            guard mirrors.first != nil else {
                throw EnrichedError(
                    code: .downloadNoMirrors,
                    step: .downloadGetUrl,
                    context: [
                        "bucket_id": bucketId,
                        "file_id": fileId
                    ],
                    cause: DownloadError.NoMirrorsFound
                )
            }
                
            try await mirrors.asyncForEach{ mirror in
                let _ = try await self.downloadEncryptedFile(
                    bucketId: bucketId,
                    fileId: fileId,
                    downloadUrl: mirror.url,
                    destinationURL: destination,
                    overwriteFile: false
                )
                
            }
            
            return DownloadResult(url: destination, expectedContentHash: nil, index: info.index)
        }
        
        guard let shards = info.shards else {
            throw EnrichedError(
                code: .downloadMissingShards,
                step: .downloadGetUrl,
                context: [
                    "bucket_id": bucketId,
                    "file_id": fileId
                ],
                cause: DownloadError.MissingShards
            )
        }
        
        
        
        if shards.count > 1 {
            throw EnrichedError(
                code: .downloadFailed,
                step: .downloadGetUrl,
                context: [
                    "bucket_id": bucketId,
                    "file_id": fileId,
                    "shard_count": String(shards.count)
                ],
                cause: DownloadError.MultipartDownloadNotSupported
            )
        }
        
        guard let shard = shards.first else {
            throw EnrichedError(
                code: .downloadMissingShards,
                step: .downloadGetUrl,
                context: [
                    "bucket_id": bucketId,
                    "file_id": fileId
                ],
                cause: DownloadError.MissingShards
            )
        }
        
        let url = try await downloadEncryptedFile(bucketId: bucketId, fileId: fileId, downloadUrl: shard.url, destinationURL: destination, progressHandler: progressHandler)
        
        return DownloadResult(url: url, expectedContentHash: shard.hash, index: info.index)
    }

    
    
    private func downloadEncryptedFile(bucketId: String, fileId: String, downloadUrl: String, destinationURL:URL, progressHandler: ProgressHandler? = nil, overwriteFile: Bool = true) async throws -> URL {
        return try await withCheckedThrowingContinuation{continuation in
            guard let requestURL = URL(string: downloadUrl) else {
                continuation.resume(throwing: EnrichedError(
                    code: .downloadS3Failed,
                    step: .downloadFromS3,
                    context: [
                        "bucket_id": bucketId,
                        "file_id": fileId
                    ],
                    cause: DownloadError.MissingDownloadURL
                ))
                return
            }
            
            let task = self.urlSession.downloadTask(with: requestURL, completionHandler: {localURL, response, error in
                if let error = error {
                    let errorCode: ErrorCode
                    var context: [String: String] = [
                        "bucket_id": bucketId,
                        "file_id": fileId
                    ]
                    
                    if let urlError = error as? URLError {
                        context["url_error_code"] = String(urlError.code.rawValue)
                        switch urlError.code {
                        case .timedOut: errorCode = .networkTimeout
                        case .notConnectedToInternet: errorCode = .networkNoConnection
                        case .networkConnectionLost: errorCode = .networkConnectionLost
                        case .cannotConnectToHost: errorCode = .networkCannotConnect
                        default: errorCode = .downloadS3Failed
                        }
                    } else {
                        errorCode = .downloadS3Failed
                    }
                    
                    continuation.resume(throwing: EnrichedError(
                        code: errorCode,
                        step: .downloadFromS3,
                        context: context,
                        cause: error
                    ))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, !(200...399).contains(httpResponse.statusCode) {
                    continuation.resume(throwing: EnrichedError(
                        code: .downloadS3Failed,
                        step: .downloadFromS3,
                        context: [
                            "bucket_id": bucketId,
                            "file_id": fileId,
                            "status_code": String(httpResponse.statusCode)
                        ],
                        cause: DownloadError.DownloadNotSuccessful
                    ))
                    return
                }
                
                if let localURL = localURL {
                    defer {
                        try? FileManager.default.removeItem(at: localURL)
                    }
                    do {
                        
                        if overwriteFile {
                            try FileManager.default.copyItem(at: localURL, to: destinationURL)
                        } else {
                            let exists = FileManager.default.fileExists(atPath: destinationURL.path)
                            
                            if exists == false {
                                FileManager.default.createFile(atPath: destinationURL.path, contents: nil)
                            }
                            try self.appendToFile(origin: localURL, destination: destinationURL)
                        }
                        
                        
                        
                        continuation.resume(returning: destinationURL)
                    } catch {
                        continuation.resume(throwing: EnrichedError(
                            code: .downloadCopyFailed,
                            step: .downloadFromS3,
                            context: [
                                "bucket_id": bucketId,
                                "file_id": fileId,
                                "destination_path": destinationURL.path
                            ],
                            cause: error
                        ))
                    }
                    
                } else {
                    continuation.resume(throwing: EnrichedError(
                        code: .downloadS3Failed,
                        step: .downloadFromS3,
                        context: [
                            "bucket_id": bucketId,
                            "file_id": fileId
                        ],
                        cause: DownloadError.MissingDownloadURL
                    ))
                }
            })
            
            observation = task.progress.observe(\.fractionCompleted) { progress, _ in
                if let progressHandlerUnwrapped = progressHandler {
                    progressHandlerUnwrapped(progress.fractionCompleted)
                }
            }
            
            task.resume()
        }
        
    }
    
    private func appendToFile(origin: URL, destination: URL) throws {
        let fileHandle = try FileHandle(forUpdating: destination)
        defer {
            fileHandle.closeFile()
        }
        fileHandle.seekToEndOfFile()
        let originData = try Data(contentsOf: origin)
        fileHandle.write(originData)
    }
}

