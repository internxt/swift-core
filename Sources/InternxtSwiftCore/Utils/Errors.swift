//
//  File.swift
//  
//
//  Created by Robert Garcia on 31/7/23.
//

import Foundation


enum CryptoError: Error {
    case badIv
    case badKey
    case badIndex(String)
    case encryptionFailed
    case decryptionFailed
    case bytesNotMatching
    case CannotGetCombinedData
}


enum ConfigLoaderError: Error {
    case NoConfigLoaded(String)
    case MissingConfigProperty(String)
}


enum APIError: Error {
    case decoding
    case server(String)
    case noInternet
    case failedRequest(String)
    case invalidResponse
}


enum ExtensionError: Swift.Error, Equatable {
    case InvalidHex
}

enum UploadError: Error {
    case InvalidIndex
    case CannotGenerateFileHash
    case FailedToFinishUpload
    case MissingUploadUrl
    case UploadNotSuccessful
    case UploadedSizeNotMatching
}


public class StartUploadError: Error {
    public var apiError: APIClientError? = nil
    public init(apiError: APIClientError? = nil) {
        self.apiError = apiError
    }
}

public class FinishUploadError: Error {
    public var apiError: APIClientError? = nil
    public init(apiError: APIClientError? = nil) {
        self.apiError = apiError
    }
}

enum NetworkFacadeError: Swift.Error, Equatable {
    case EncryptionFailed
    case FailedToOpenEncryptOutputStream
    case FailedToOpenDecryptOutputStream
    case FailedToOpenDecryptInputStream
    case EncryptedFileNotSameSizeAsOriginal
    case DecryptionFailed
}
