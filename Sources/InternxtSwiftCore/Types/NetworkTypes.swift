//
//  NetworkTypes.swift
//  
//
//  Created by Robert Garcia on 4/8/23.
//

import Foundation

public struct NetworkUploadPayload: Codable {
    let index: Int
    let size: Int
}
public struct StartUploadPayload: Codable {
    let uploads: Array<NetworkUploadPayload>
    
    
}

public struct UploadResult: Decodable {
    let uuid: String
    let url: String?
    let urls: Array<String>
    let UploadId: String?
}

public struct StartUploadEndpoint: Endpoint {
    var path: String
    
    let body: Codable?
    
    let method =  HTTPMethod.POST
    
    init(body: Codable?) {
        self.body = body
        self.path = ""
    }
}
