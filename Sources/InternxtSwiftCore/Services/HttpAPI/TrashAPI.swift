//
//  TrashAPI.swift
//  
//
//  Created by Robert Garcia on 7/8/23.
//

import Foundation

@available(macOS 10.15, *)
public struct TrashAPI {
    private let baseUrl: String
    private let apiClient: APIClient
    
    public init(baseUrl: String, authToken: String) {
        self.baseUrl = baseUrl
        self.apiClient = APIClient(urlSession: URLSession.shared, token: authToken)
    }
    
    public func trashItems(itemsToTrash: AddItemsToTrashPayload, debug: Bool = false) async throws -> Bool {
        let endpoint = AddItemsToTrashEndpoint(path: "\(self.baseUrl)/storage/trash/add", body: itemsToTrash.toJson())
        
        do {
            try await apiClient.fetch(type: AddItemsToTrashResponse.self, endpoint, debugResponse: debug)
            
            return true
        } catch {
            guard let apiClientError = error as? APIClientError else {
                throw error
            }
            // Trash endpoint doesn't return a body, instead we know if the request was successful by the statusCode,
            // the APIClient will throw an empty body error in this case with a 200 status code
            return apiClientError.statusCode == 200
        }
    }
}