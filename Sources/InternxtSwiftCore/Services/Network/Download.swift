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
public class Download: NSObject {
    private let networkAPI: NetworkAPI
    
    private var observation: NSKeyValueObservation?

    private var progressHandlersByTaskID = [Int : ProgressHandler]()
    private var urlSession: URLSession
    init(networkAPI: NetworkAPI, urlSession: URLSession?) {
        self.networkAPI = networkAPI
        if let urlSession = urlSession {
            self.urlSession = urlSession
        } else {
            self.urlSession = URLSession.shared
        }
        
        super.init()
    }
    
    deinit {
        observation?.invalidate()
    }
    
    
    func start(bucketId: String, fileId: String, destination: URL,  progressHandler: ProgressHandler? = nil,  debug: Bool = false) async throws ->  DownloadResult {
        let info = try await networkAPI.getFileInfo(bucketId: bucketId, fileId: fileId)
        
        if info.shards.count > 1 {
            throw DownloadError.MultipartDownloadNotSupported
        }
        
        let shard = info.shards.first!
        
        let url = try await downloadEncryptedFile(downloadUrl: shard.url, destinationURL: destination, progressHandler: progressHandler)
        
        return DownloadResult(url: url, expectedContentHash: shard.hash, index: info.index)
    }
    
    
    
    private func downloadEncryptedFile(downloadUrl: String, destinationURL:URL, progressHandler: ProgressHandler? = nil) async throws -> URL {
        let task = urlSession.downloadTask(with: URL(string: downloadUrl)!, completionHandler: {_,_,_ in
            print("COMPLETED")
        })
        
        observation = task.progress.observe(\.fractionCompleted) { progress, _ in
             print("progress: ", progress.fractionCompleted)
        }
        if progressHandler != nil {
            progressHandlersByTaskID[task.taskIdentifier] = progressHandler
        }
        task.resume()
        
        
        return destinationURL
    }
}

