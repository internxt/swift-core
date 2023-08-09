//
//  Endpoint.swift
//  
//
//  Created by Robert Garcia on 4/8/23.
//

import Foundation

public enum HTTPMethod: String {
    case POST = "POST"
    case GET = "GET"
}


public struct Endpoint {
    public var path: String
    public var method: HTTPMethod
    public var body: Data?
    init(path: String, method: HTTPMethod = HTTPMethod.GET, body: Data? = nil) {
        self.path = path
        self.method = method
        self.body = body
    }
}

