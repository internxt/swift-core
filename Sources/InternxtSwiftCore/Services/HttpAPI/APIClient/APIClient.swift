//
//  ApiClient.swift
//  
//
//  Created by Robert Garcia on 1/8/23.
//

import Foundation
import Combine

public struct APIClientError: Error {
    public var statusCode: Int
    public var responseBody: Data
    private var message: String
    public var localizedDescription: String {
        return self.message
    }
    public init(statusCode: Int, message: String, responseBody: Data = Data()) {
        self.statusCode = statusCode
        self.message = message
        self.responseBody = responseBody
    }
}



@available(macOS 10.15, *)
struct APIClient {
    private let urlSession: URLSession
    private let authorizationHeaderValue: String?
        
    init(urlSession: URLSession = URLSession.shared,
             authorizationHeaderValue: String? = nil) {
        self.urlSession = urlSession
        self.authorizationHeaderValue = authorizationHeaderValue
    }
    
  
    func fetch<T: Decodable>(type: T.Type? , _ endpoint: Endpoint, debugResponse: Bool?) async throws -> T  {
        let request: URLRequest = try buildURLRequest(endpoint: endpoint)
        
        return try await withCheckedThrowingContinuation { continuation in
            
            let task = urlSession.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    continuation.resume(with: .failure(APIError.failedRequest(error.localizedDescription)))
                    return
                }
                let httpResponse = response as! HTTPURLResponse

                do {
                    
                    if data == nil {
                        throw APIClientError(statusCode: httpResponse.statusCode, message: "Response is empty")
                    }
                    
                    if(debugResponse == true) {
                        print("\(endpoint.path) response is \(String(decoding: data!, as: UTF8.self))")
                    }
                    let json = try JSONDecoder().decode(T.self, from: data!)
                    continuation.resume(with:.success(json))
                } catch {
                    if debugResponse == true {
                        print("API CLIENT ERROR", error)
                    }
                    continuation.resume(with:.failure(APIClientError(statusCode: httpResponse.statusCode, message: error.localizedDescription, responseBody: data ?? Data())))
                }
            }
            task.resume()
        }
    }
    
    
    private func buildURLRequest(endpoint: Endpoint) throws -> URLRequest {
        guard let url = URL(string: endpoint.path) else {
            throw APIClientError(statusCode: -1, message: "Unable to build URL from \(endpoint.path)")
        }
   
        var urlRequest = URLRequest(url: url )
        urlRequest.httpMethod = endpoint.method.rawValue.lowercased()
        
       
        
        if let authorizationHeaderValue = self.authorizationHeaderValue {
            urlRequest.setValue(authorizationHeaderValue, forHTTPHeaderField:"Authorization")
        }
        
        if let body = endpoint.body {
            urlRequest.httpBody = body
        }
        
            
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return urlRequest
    }
}
