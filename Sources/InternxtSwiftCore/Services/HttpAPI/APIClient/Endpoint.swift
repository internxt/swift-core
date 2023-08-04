//
//  Endpoint.swift
//  
//
//  Created by Robert Garcia on 4/8/23.
//

import Foundation

enum HTTPMethod: String {
    case POST
    case GET
}
protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var body: Codable? { get }
}


extension Endpoint {
    var path: String { "" }
    var method: HTTPMethod { .GET }
    var parameters: [String: AnyObject]? { nil }
}
