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
    private var message: String
    public var localizedDescription: String {
        return self.message
    }
    public init(statusCode: Int, message: String) {
        self.statusCode = statusCode
        self.message = message
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
            
            let task = URLSession(configuration: .default).dataTask(with: request) { (data, response, error) in
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
                    print("Unable to Decode Response \(error)")
                    continuation.resume(with:.failure(APIClientError(statusCode: httpResponse.statusCode, message: error.localizedDescription)))
                    
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
        
       
        
        if self.authorizationHeaderValue != nil {
            urlRequest.setValue(self.authorizationHeaderValue, forHTTPHeaderField:"Authorization")
        }
        
        if endpoint.body != nil {
            print("Endpoint body \(String(data: endpoint.body!, encoding: .utf8))")
            urlRequest.httpBody = endpoint.body!
        }
            
        
        
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return urlRequest
    }
}
