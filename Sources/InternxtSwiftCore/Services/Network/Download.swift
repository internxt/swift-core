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
    public var index: String
    init(url: URL, expectedContentHash: String, index: String) {
        self.url = url
        self.expectedContentHash = expectedContentHash
        self.index = index
    }
}

@available(macOS 10.15, *)
extension Download: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("DONE DOWNLOAD")
    }
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("WRITING bytes")
    }
}

@available(macOS 10.15, *)
public class Download: NSObject {
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
        
    }
    
    func start(bucketId: String, fileId: String, destination: URL,  progressHandler: ProgressHandler? = nil, debug: Bool = false) async throws -> DownloadResult {
        let info = try await networkAPI.getFileInfo(bucketId: bucketId, fileId: fileId)
        
        if info.shards.count > 1 {
            throw DownloadError.MultipartDownloadNotSupported
        }
        
        let shard = info.shards.first!
        
        let url = try await downloadEncryptedFile(downloadUrl: shard.url, destinationUrl: destination, progressHandler: progressHandler)
        
        
        if url.fileSize == 0 {
            print("EMPTY FILE")
        }
        return DownloadResult(url: url, expectedContentHash: shard.hash, index: shard.index)
        
    }
    
    
    
    
    
    
    private func downloadEncryptedFile(downloadUrl: String, destinationUrl:URL, progressHandler: ProgressHandler? = nil) async throws -> URL  {
        return try await withCheckedThrowingContinuation { (continuation) in
           
            
            let task = urlSession.downloadTask(
                with: URL(string: downloadUrl)!,
                completionHandler: { localURL, res, error in
                    guard let error = error else {
                        let response = res as? HTTPURLResponse
                        if response?.statusCode != 200 {
                            return continuation.resume(with: .failure(DownloadError.DownloadNotSuccessful))
                        } else {
                            if let localURL = localURL {
                                do {
                                    try FileManager.default.copyItem(at: localURL, to: destinationUrl)
                                    return continuation.resume(with: .success(destinationUrl))
                                } catch {
                                    return continuation.resume(with: .failure(DownloadError.MissingDownloadURL))
                                }
                                
                                
                            } else {
                                return continuation.resume(with: .failure(DownloadError.MissingDownloadURL))
                            }
                            
                        }
                        
                    }
                    
                    continuation.resume(throwing: error)
                }
            )
            
            print("Progress")
            print(progressHandler)
            if progressHandler != nil {
                progressHandlersByTaskID[task.taskIdentifier] = progressHandler
            }
            
            
            task.resume()
        }
    }
}

