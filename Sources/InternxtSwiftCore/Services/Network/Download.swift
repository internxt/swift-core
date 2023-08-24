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
        
        
        if let infoUnwrapped = info {
            do {
                try FileManager.default.copyItem(at: location, to: destinationURL!)
                completionHandler(DownloadResult(url: location, expectedContentHash: infoUnwrapped.shards.first!.hash, index: infoUnwrapped.index))
            } catch {
                completionHandler(nil)
            }
            
        } else {
            completionHandler(nil)
        }
        
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        let handler = progressHandlersByTaskID[downloadTask.taskIdentifier]
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
    private var completionHandler: (DownloadResult?) -> Void
    private var info: GetFileInfoResponse?
    private var destinationURL: URL?
    init(networkAPI: NetworkAPI, urlSession: URLSession? = nil) {
        self.networkAPI = networkAPI
        self.completionHandler = {downloadResult in
            print("Completed")
        }
        super.init()
        
    }
    
    
    
    func start(bucketId: String, fileId: String, destination: URL,  progressHandler: ProgressHandler? = nil, completionHandler: @escaping (DownloadResult?) -> Void,  debug: Bool = false) async throws ->  Void {
        self.completionHandler = completionHandler
        self.destinationURL = destination
        let info = try await networkAPI.getFileInfo(bucketId: bucketId, fileId: fileId)
        
        self.outputStream = OutputStream(url: destination, append: true)
        if info.shards.count > 1 {
            throw DownloadError.MultipartDownloadNotSupported
        }
        
        self.info = info
        let shard = info.shards.first!
        
        downloadEncryptedFile(downloadUrl: shard.url, destinationUrl: destination, progressHandler: progressHandler)
        
    }
    
    
    
    private func downloadEncryptedFile(downloadUrl: String, destinationUrl:URL, progressHandler: ProgressHandler? = nil) -> Void {
        let task = urlSession.downloadTask(with: URL(string: downloadUrl)!)
        
    
        if progressHandler != nil {
            progressHandlersByTaskID[task.taskIdentifier] = progressHandler
        }
        task.resume()
    }
}

