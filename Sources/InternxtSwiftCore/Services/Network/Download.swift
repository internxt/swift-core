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
    init(networkAPI: NetworkAPI, urlSession: URLSession? = nil) {
        self.networkAPI = networkAPI
        self.completionHandler = {downloadResult in
            print("Completed")
        }
        super.init()
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        if let infoUnwrapped = info {
            completionHandler(DownloadResult(url: location, expectedContentHash: infoUnwrapped.shards.first!.hash, index: infoUnwrapped.index))
        }
        
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // Calculate and handle download progress
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        print("Download Progress: \(progress)")
    }
    
    func start(bucketId: String, fileId: String, destination: URL,  progressHandler: ProgressHandler? = nil, completionHandler: @escaping (DownloadResult?) -> Void,  debug: Bool = false) async throws ->  Void {
        self.completionHandler = completionHandler
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

