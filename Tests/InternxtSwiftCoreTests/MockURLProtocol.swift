//
//  MockURLProtocol.swift
//  
//
//  Created by Robert Garcia on 11/8/23.
//

import Foundation


class MockURLProtocol: URLProtocol {
  static var requestHandler: ((URLRequest) async throws -> (HTTPURLResponse, Data?))?

  override class func canInit(with request: URLRequest) -> Bool {
    // To check if this protocol can handle the given request.
    return true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    // Here you return the canonical version of the request but most of the time you pass the orignal one.
    return request
  }

  override func startLoading() {
      guard let handler = MockURLProtocol.requestHandler else {
          fatalError("RequestHandler is unavailable")
        }
          
      Task {
          do {
              // 2. Call handler with received request and capture the tuple of response and data.
              let (response, data) = try await handler(request)
              // 3. Send received response to the client.
              self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
              
              if let data = data {
                  // 4. Send received data to the client.
                  self.client?.urlProtocol(self, didLoad: data)
              }
              // 5. Notify request has been finished.
              self.client?.urlProtocolDidFinishLoading(self)
          } catch {
              // 6. Notify received error.
              self.client?.urlProtocol(self, didFailWithError: error)
          }
      }
  }

  override func stopLoading() {
    // This is called if the request gets canceled or completed.
  }
}
