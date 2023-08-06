//
//  ApiClient.swift
//  
//
//  Created by Robert Garcia on 1/8/23.
//

import Foundation
import Combine

@available(macOS 10.15, *)
struct APIClient {
    private let urlSession: URLSession
    private let token: String
        
    init(urlSession: URLSession = URLSession.shared,
             token: String = "") {
        self.urlSession = urlSession
        self.token = token
    }
    
  
    func fetch<T: Decodable>(type: T.Type , _ endpoint: Endpoint) async throws -> T  {
       
        return try await withCheckedThrowingContinuation { continuation in
            let request = self.buildURLRequest(endpoint: endpoint)
                    
            if(request == nil) {
                continuation.resume(throwing: APIError.failedRequest("Unable to build request"))
            }
            
            let task = URLSession(configuration: .default).dataTask(with: request!) { (data, response, error) in
                if let error = error {
                    continuation.resume(with: .failure(APIError.failedRequest(error.localizedDescription)))
                    return
                }
                
                do {
                    if(data == nil) {
                        continuation.resume(with:.failure(APIError.invalidResponse))
                        return
                    }
                    let json = try JSONDecoder().decode(T.self, from: data!)
                    continuation.resume(with:.success(json))
                } catch {
                    print("Unable to Decode Response \(error)")
                    continuation.resume(with:.failure(APIError.invalidResponse))
                    
                }
            }
        }
        
        
        
    }
    
    
    private func buildURLRequest(endpoint: Endpoint) -> URLRequest? {
        var urlRequest = URLRequest(url: URL(string: endpoint.path)!)
        urlRequest.httpMethod = endpoint.method.rawValue
                
        if let body = endpoint.parameters,
            !body.isEmpty,
            let postData = (try? JSONSerialization.data(withJSONObject: endpoint.body as Any, options: [])) {
            urlRequest.httpBody = postData
        }
        
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return urlRequest
    }
}
