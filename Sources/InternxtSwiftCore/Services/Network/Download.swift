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
extension Download: URLSessionDataDelegate {
    
    public func urlSession(
            _ session: URLSession,
            task: URLSessionTask,
            didSendBodyData bytesSent: Int64,
            totalBytesSent: Int64,
            totalBytesExpectedToSend: Int64
    ) {
            print("PROGRESS")
            
            let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        print(progress)
            let handler = progressHandlersByTaskID[task.taskIdentifier]
            handler?(progress)
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
    private var outputStream: OutputStream?
    private var progressHandlersByTaskID = [Int : ProgressHandler]()
    init(networkAPI: NetworkAPI, urlSession: URLSession? = nil) {
        self.networkAPI = networkAPI
        super.init()
        
    }
    
    func start(bucketId: String, fileId: String, destination: URL,  progressHandler: ProgressHandler? = nil, debug: Bool = false) async throws -> DownloadResult {
        let info = try await networkAPI.getFileInfo(bucketId: bucketId, fileId: fileId)
        
        self.outputStream = OutputStream(url: destination, append: true)
        if info.shards.count > 1 {
            throw DownloadError.MultipartDownloadNotSupported
        }
        
        let shard = info.shards.first!
        
        let url = try await downloadEncryptedFile(downloadUrl: shard.url, destinationUrl: destination, progressHandler: progressHandler)
        
        
        if url.fileSize == 0 {
            throw NetworkFacadeError.FileIsEmpty
        }
        return DownloadResult(url: url, expectedContentHash: shard.hash, index: info.index)
        
    }
    
    
    
    private func downloadEncryptedFile(downloadUrl: String, destinationUrl:URL, progressHandler: ProgressHandler? = nil) async throws -> URL  {
        return try await withCheckedThrowingContinuation { (continuation) in
           
            let task = urlSession.dataTask(
                with: URL(string: downloadUrl)!,
                completionHandler: { data, res, error in
                    guard let error = error else {
                        let response = res as? HTTPURLResponse
                        if response?.statusCode != 200 {
                            return continuation.resume(with: .failure(DownloadError.DownloadNotSuccessful))
                        } else {
                            if let dataUnwrapped = data {
                                do {
                                    try dataUnwrapped.write(to: destinationUrl)
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
            
           
            if progressHandler != nil {
                progressHandlersByTaskID[task.taskIdentifier] = progressHandler
            }
            
            
            task.resume()
            outputStream?.open()
        }
    }
}

