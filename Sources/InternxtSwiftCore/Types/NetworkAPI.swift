//
//  NetworkAPI.swift
//  
//
//  Created by Robert Garcia on 4/8/23.
//

import Foundation

struct NetworkUploadPayload: Codable {
    let index: Int
    let size: Int
}
struct StartUploadPayload: Codable {
    let uploads: Array<NetworkUploadPayload>
    
    
}

struct UploadResult: Decodable {
    let uuid: String
    let url: String?
    let urls: Array<String>
    let UploadId: String?
}

struct StartUploadEndpoint: Endpoint {
    let body: Codable?
    
    let method =  HTTPMethod.POST
    
    init(body: Codable?) {
        self.body = body
    }
}
