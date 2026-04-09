//
//  File.swift
//  
//
//  Created by Robert Garcia on 31/7/23.
//

import Foundation

// MARK: - Error Codes
public enum ErrorCode: String {
    // Upload (UPL-XXX)
    case uploadStartFailed = "UPL-001"
    case uploadS3Timeout = "UPL-002"
    case uploadS3Failed = "UPL-003"
    case uploadFinishFailed = "UPL-004"
    case uploadEncryptionFailed = "UPL-005"
    case uploadSizeMismatch = "UPL-006"
    case uploadMissingUrl = "UPL-007"
    case uploadInvalidIndex = "UPL-008"
    case uploadCannotGenerateHash = "UPL-009"
    case uploadMissingEtag = "UPL-010"
    case uploadMissingChunk = "UPL-011"
    case uploadPartFailed = "UPL-012"
    
    // Download (DWN-XXX)
    case downloadFailed = "DWN-001"
    case downloadDecryptionFailed = "DWN-002"
    case downloadHashMismatch = "DWN-003"
    case downloadFileEmpty = "DWN-004"
    case downloadInvalidBucket = "DWN-005"
    case downloadInfoFailed = "DWN-006"
    case downloadMirrorsFailed = "DWN-007"
    case downloadS3Failed = "DWN-008"
    case downloadCopyFailed = "DWN-009"
    case downloadNoMirrors = "DWN-010"
    case downloadMissingShards = "DWN-011"
    
    // Network (NET-XXX)
    case networkTimeout = "NET-001"
    case networkNoConnection = "NET-002"
    case networkConnectionLost = "NET-003"
    case networkCannotConnect = "NET-004"
    
    // API (API-XXX)
    case apiBadRequest = "API-400"
    case apiUnauthorized = "API-401"
    case apiPaymentRequired = "API-402"
    case apiNotFound = "API-404"
    case apiConflict = "API-409"
    case apiServerError = "API-500"
    case apiUnknown = "API-000"
    
    // Encryption (ENC-XXX)
    case encryptionFailed = "ENC-001"
    case encryptionStreamFailed = "ENC-002"
    case encryptionSizeMismatch = "ENC-003"
    
    // Decryption (DEC-XXX)
    case decryptionFailed = "DEC-001"
    case decryptionStreamFailed = "DEC-002"
}

// MARK: - Operation Steps
public enum OperationStep: String {
    // Upload steps
    case uploadStart = "upload/start"
    case uploadEncrypt = "upload/encrypt"
    case uploadToS3 = "upload/s3-put"
    case uploadFinish = "upload/finish"
    case uploadCreateFile = "upload/create-file"
    case uploadMultipartStart = "upload/multipart-start"
    case uploadMultipartPart = "upload/multipart-part"
    case uploadMultipartFinish = "upload/multipart-finish"
    
    // Download steps
    case downloadGetInfo = "download/get-info"
    case downloadGetUrl = "download/get-url"
    case downloadFromS3 = "download/s3-get"
    case downloadDecrypt = "download/decrypt"
}

// MARK: - Enriched Error
public struct EnrichedError: Error, LocalizedError {
    public let code: ErrorCode
    public let step: OperationStep
    public let context: [String: String]
    public let cause: Error?
    public let timestamp: Date
    
    public init(
        code: ErrorCode,
        step: OperationStep,
        context: [String: String] = [:],
        cause: Error? = nil
    ) {
        self.code = code
        self.step = step
        self.context = context
        self.cause = cause
        self.timestamp = Date()
    }
    
    public var errorDescription: String? {
        var parts = ["[\(code.rawValue)]", "Step: \(step.rawValue)"]
        
        if !context.isEmpty {
            let contextStr = context.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            parts.append("| \(contextStr)")
        }
        
        if let cause = cause {
            parts.append("| Cause: \(cause.localizedDescription)")
        }
        
        return parts.joined(separator: " ")
    }
}

// MARK: - Existing Errors

enum CryptoError: Error, Equatable {
    case badIv
    case badKey
    case badIndex(String)
    case encryptionFailed
    case decryptionFailed
    case bytesNotMatching
    case CannotGetCombinedData
    case invalidBase64String
    case emptyBase64String
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

public enum UploadError: Error, Equatable {
    case InvalidIndex
    case CannotGenerateFileHash
    case FailedToFinishUpload
    case MissingUploadUrl
    case UploadNotSuccessful
    case UploadedSizeNotMatching
    case MissingEtag
    case MissingChunk
    case PartUploadFailed(partIndex: Int, error: Error)

    public static func == (lhs: UploadError, rhs: UploadError) -> Bool {
        switch (lhs, rhs) {
        case (.InvalidIndex, .InvalidIndex),
             (.CannotGenerateFileHash, .CannotGenerateFileHash),
             (.FailedToFinishUpload, .FailedToFinishUpload),
             (.MissingUploadUrl, .MissingUploadUrl),
             (.UploadNotSuccessful, .UploadNotSuccessful),
             (.UploadedSizeNotMatching, .UploadedSizeNotMatching),
             (.MissingChunk, .MissingChunk),
             (.MissingEtag, .MissingEtag):
            return true
        case let (.PartUploadFailed(lhsPartIndex, lhsError), .PartUploadFailed(rhsPartIndex, rhsError)):
            return lhsPartIndex == rhsPartIndex && lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
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
    case HashMissmatch
    case FileIsEmpty
}
