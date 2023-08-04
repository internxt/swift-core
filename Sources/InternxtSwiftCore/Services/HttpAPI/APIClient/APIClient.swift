//
//  ApiClient.swift
//  
//
//  Created by Robert Garcia on 1/8/23.
//

import Foundation


struct APIClient {
    private let urlSession: URLSession
    private let token: String
        
    init(urlSession: URLSession = URLSession.shared,
             token: String = "") {
        self.urlSession = urlSession
        self.token = token
    }
    
    
    func fetch<T>(with endpoint: Endpoint, completionBlock: @escaping (Result<Optional<T>, Error>) -> ()) {
        let urlRequest = buildURLRequest(endpoint: endpoint)!
        
        let task = urlSession.dataTask(with: urlRequest) {
            data, response, error in
            guard let error = error else {
                if(data == nil) {
                    completionBlock(.success(nil))
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: [])
                    completionBlock(.success(json as? T))
                    return
                } catch {
                    completionBlock(.failure(error))
                    return
                }
                
            }
            completionBlock(.failure(error))
        }

        task.resume()
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
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
}
