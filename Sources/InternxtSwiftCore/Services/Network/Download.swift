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
        if bucketId.isValidHex == false {
            throw DownloadError.InvalidBucketId
        }
        let info = try await networkAPI.getFileInfo(bucketId: bucketId, fileId: fileId, debug: debug)
        
        if info.version == 1 {
            let mirrors = try await networkAPI.getFileMirrors(bucketId: bucketId, fileId: fileId, debug: debug)
            
            guard let mirror = mirrors.first else {
                throw DownloadError.NoMirrorsFound
            }
            
            if mirrors.count > 1 {
                // Legacy download here
                
                try await mirrors.asyncForEach{ mirror in
                    let encryptedFileURL = try await downloadEncryptedFile(
                        downloadUrl: mirror.url,
                        destinationURL: destination,
                        overwriteFile: false
                    )
                    
                    print("FILE SIZE ON MIRROR \(mirror.hash)", encryptedFileURL.fileSize)
                }
                
                return DownloadResult(url: destination, expectedContentHash: "NO_CONTENT_HASH", index: info.index)
            }
            
            
            let url = try await downloadEncryptedFile(downloadUrl: mirror.url, destinationURL: destination, progressHandler: progressHandler)
            
            return DownloadResult(url: url, expectedContentHash: mirror.hash, index: info.index)
        }
        
        guard let shards = info.shards else {
            throw DownloadError.MissingShards
        }
        
        
        
        if shards.count > 1 {
            throw DownloadError.MultipartDownloadNotSupported
        }
        
        guard let shard = shards.first else {
            throw DownloadError.MissingShards
        }
        
        let url = try await downloadEncryptedFile(downloadUrl: shard.url, destinationURL: destination, progressHandler: progressHandler)
        
        return DownloadResult(url: url, expectedContentHash: shard.hash, index: info.index)
    }

    
    
    private func downloadEncryptedFile(downloadUrl: String, destinationURL:URL, progressHandler: ProgressHandler? = nil, overwriteFile: Bool = true) async throws -> URL {
        return try await withCheckedThrowingContinuation{continuation in
            let task = urlSession.downloadTask(with: URL(string: downloadUrl)!, completionHandler: {localURL,_,_ in
                if let localURL = localURL {
                    defer {
                        try? FileManager.default.removeItem(at: localURL)
                    }
                    do {
                        
                        if overwriteFile {
                            try FileManager.default.copyItem(at: localURL, to: destinationURL)
                        } else {
                            try self.appendToFile(origin: localURL, destination: destinationURL)
                        }
                        
                        
                        
                        continuation.resume(returning: destinationURL)
                    } catch {
                        continuation.resume(throwing: DownloadError.FailedToCopyDownloadedURL)
                    }
                    
                } else {
                    continuation.resume(throwing: DownloadError.MissingDownloadURL)
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

