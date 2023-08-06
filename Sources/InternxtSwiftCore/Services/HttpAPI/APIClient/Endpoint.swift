//
//  Endpoint.swift
//  
//
//  Created by Robert Garcia on 4/8/23.
//

import Foundation

enum HTTPMethod: String {
    case POST = "POST"
    case GET = "GET"
}
protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var body: Encodable? { get }
}

