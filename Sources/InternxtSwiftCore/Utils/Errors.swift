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
    case encryptionFailed
    case decryptionFailed
}
