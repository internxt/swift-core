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
    var urlSession: URLSession = URLSession.shared
    var authorizationHeaderValue: String? = nil
    var clientName: String? = nil
    var clientVersion: String? = nil

    
    
  
    func fetch<T: Decodable>(type: T.Type? , _ endpoint: Endpoint, debugResponse: Bool?) async throws -> T  {
        let request: URLRequest = try buildURLRequest(endpoint: endpoint)
        
        return try await withCheckedThrowingContinuation { continuation in
            
            let task = urlSession.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    if debugResponse == true {
                        print("API CLIENT ERROR", error)
                    }
                    continuation.resume(with: .failure(APIError.failedRequest(error.localizedDescription)))
                    return
                }
                
                func finishWithErrorMessage(message: String) {
                    
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
                } catch let DecodingError.dataCorrupted(context) {
                    let message = context.debugDescription
                    continuation.resume(with:.failure(APIClientError(statusCode: httpResponse.statusCode, message: message, responseBody: data ?? Data())))
                } catch let DecodingError.keyNotFound(key, context) {
                    let message = "Key '\(key)' not found: \(context.debugDescription)"
                    continuation.resume(with:.failure(APIClientError(statusCode: httpResponse.statusCode, message: message, responseBody: data ?? Data())))
                } catch let DecodingError.valueNotFound(value, context) {
                    let message = "Value '\(value)' not found: \(context.debugDescription)"
                    continuation.resume(with:.failure(APIClientError(statusCode: httpResponse.statusCode, message: message, responseBody: data ?? Data())))
                } catch let DecodingError.typeMismatch(type, context)  {
                    let message = "Type '\(type)' mismatch: \(context.debugDescription)"
                    continuation.resume(with:.failure(APIClientError(statusCode: httpResponse.statusCode, message: message, responseBody: data ?? Data())))
                } catch {
                    let message = error.localizedDescription
                    continuation.resume(with:.failure(APIClientError(statusCode: httpResponse.statusCode, message: message, responseBody: data ?? Data())))
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

        urlRequest.setValue(clientName, forHTTPHeaderField: "internxt-client")
        urlRequest.setValue(clientVersion, forHTTPHeaderField: "internxt-version")
        
        print("HEADERS", urlRequest.allHTTPHeaderFields)
        if let body = endpoint.body {
            urlRequest.httpBody = body
        }
        
            
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return urlRequest
    }
}
