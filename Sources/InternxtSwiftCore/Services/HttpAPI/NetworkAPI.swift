//
//  NetworkAPI.swift
//  
//
//  Created by Robert Garcia on 4/8/23.
//

import Foundation


@available(macOS 10.15, *)
public struct NetworkAPI {
    private let baseUrl: String
    private let apiClient: APIClient

    public init(baseUrl: String, basicAuthToken: String, urlSession: URLSession? = nil, clientName: String, clientVersion: String, gatewayHeader: String? = nil) {
        self.baseUrl = baseUrl
        let session = urlSession ?? APIClient.ephemeralSession
        self.apiClient = APIClient(urlSession: session, authorizationHeaderValue: "Basic \(basicAuthToken)", clientName: clientName, clientVersion: clientVersion,
                                   authorizationHeaderGatewayValue: gatewayHeader)
    }
    
    public func startUpload(bucketId: String,  uploadSize: Int,parts: Int = 1, debug: Bool = false) async throws -> StartUploadResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/v2/buckets/\(bucketId)/files/start?multiparts=\(String(parts))",
            method: .POST,
            body: StartUploadPayload(
                uploads: [NetworkUploadPayload(
                    index: 0,
                    size: uploadSize
                )]
            ).toJson()
        )
        
        return try await apiClient.fetch(type: StartUploadResponse.self, endpoint, debugResponse: debug)
    }
    
    public func finishUpload(bucketId: String, payload: FinishUploadPayload, debug: Bool = false) async throws -> FinishUploadResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/v2/buckets/\(bucketId)/files/finish",
            method: .POST,
            body: payload.toJson()
        )
        return try await apiClient.fetch(type: FinishUploadResponse.self, endpoint, debugResponse: debug)
    }
    
    
    public func getFileInfo(bucketId: String, fileId: String, debug: Bool = false) async throws -> GetFileInfoResponse {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/buckets/\(bucketId)/files/\(fileId)/info",
            method: .GET
        )
        return try await apiClient.fetch(type: GetFileInfoResponse.self, endpoint, debugResponse: debug)
    }
    
    public func getFileMirrors(bucketId: String, fileId: String, debug: Bool = false) async throws -> [FileMirrorShard] {
        let endpoint = Endpoint(
            path: "\(self.baseUrl)/buckets/\(bucketId)/files/\(fileId)?limit=3&skip=0",
            method: .GET
        )
        return try await apiClient.fetch(type: [FileMirrorShard].self, endpoint, debugResponse: debug)
    }
}
