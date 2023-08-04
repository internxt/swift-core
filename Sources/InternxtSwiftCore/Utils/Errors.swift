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
    case badIndex("Index should be 32 bytes length")
    case encryptionFailed
    case decryptionFailed
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


enum ExtensionError: Error {
    case InvalidHex(String)
}

enum UploadError: Error {
    case InvalidIndex
}


