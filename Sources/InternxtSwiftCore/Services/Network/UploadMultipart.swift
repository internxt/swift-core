//
//  UploadMultipart.swift
//
//
//  Created by Robert Garcia on 15/11/23.
//

import Foundation


enum UploadMultipartError: Error {
    case CannotOpenInputStream
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

let PART_SIZE: Double = 30 * 1024 * 1024

@available(macOS 10.15, *)
public class UploadMultipart: NSObject {
    private let encrypt = Encrypt()
    private let cryptoUtils = CryptoUtils()
    private let fileManager = FileManager.default
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
        if urlSession != nil {
            self.urlSession = urlSession!
        }
    }
    
    func start(encryptedFileURL: URL, key: [UInt8], iv: [UInt8], debug: Bool = false, progressHandler: ProgressHandler? = nil) async throws -> Void {
        
        let fileSize = encryptedFileURL.fileSize
        
        let parts = ceil(Double(fileSize) / PART_SIZE)
        
        guard let inputStream = InputStream(url: encryptedFileURL) else {
            throw UploadMultipartError.CannotOpenInputStream
        }
        
        func uploadEncryptedChunk(chunk: Data) -> Void {
            
        }
        
        
        /*try self.encryptFileIntoChunks(
            inputStream: inputStream,
            key: key,
            iv: iv,
            fileChunkReady: uploadEncryptedChunk
        )
        
        let uploadStart = try await networkAPI.startUpload(bucketId: bucketId, uploadSize: Int(fileSize), debug: debug)*/
    }
    
    func uploadEncryptedChunk() -> Void {
        
    }
    
    
    
}
