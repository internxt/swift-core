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
}

struct DownloadResult {
    public var url: URL
    public var expectedContentHash: String
    init(url: URL, expectedContentHash: String) {
        self.url = url
        self.expectedContentHash = expectedContentHash
    }
}

@available(macOS 10.15, *)
extension Download: URLSessionTaskDelegate {
    public func urlSession(
            _ session: URLSession,
            task: URLSessionTask,
            didSendBodyData bytesSent: Int64,
            totalBytesSent: Int64,
            totalBytesExpectedToSend: Int64
    ) {
            let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
            let handler = progressHandlersByTaskID[task.taskIdentifier]
            print("Progress URLSESSION \(progress)")
            handler?(progress)
        }
}

@available(macOS 10.15, *)
public class Download: NSObject {
    private let networkAPI: NetworkAPI
    private lazy var urlSession = URLSession(
        configuration: .ephemeral,
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
    
    func start(bucketId: String, fileId: String, progressHandler: ProgressHandler? = nil, debug: Bool = false) async throws -> DownloadResult {
        let info = try await networkAPI.getFileInfo(bucketId: bucketId, fileId: fileId)
        
        if info.shards.count > 1 {
            throw DownloadError.MultipartDownloadNotSupported
        }
        
        let shard = info.shards.first!
        
        let url = try await downloadEncryptedFile(downloadUrl: shard.url, progressHandler: progressHandler)
       
        return DownloadResult(url: url, expectedContentHash: shard.hash)
        
    }
    
    private func downloadEncryptedFile(downloadUrl: String, progressHandler: ProgressHandler? = nil) async throws -> URL  {
        return try await withCheckedThrowingContinuation { (continuation) in
            var request = URLRequest(
                url: URL(string: downloadUrl)!,
                cachePolicy: .reloadIgnoringLocalCacheData
            )
            
            request.httpMethod = "GET"
            
            let task = urlSession.downloadTask(
                with: request,
                completionHandler: { localURL, res, error in
                    guard let error = error else {
                        let response = res as? HTTPURLResponse
                        if response?.statusCode != 200 {
                            return continuation.resume(with: .failure(DownloadError.DownloadNotSuccessful))
                        } else {
                            if let url = localURL {
                                return continuation.resume(with: .success(url))
                            } else {
                                return continuation.resume(with: .failure(DownloadError.MissingDownloadURL))
                            }
                            
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

