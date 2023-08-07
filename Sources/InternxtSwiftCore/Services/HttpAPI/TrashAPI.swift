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
    
    public func trashItems(itemsToTrash: AddItemsToTrashPayload) async throws -> Void {
        let endpoint = AddItemsToTrashEndpoint(path: "\(self.baseUrl)/storage/trash/add", body: itemsToTrash.toJson())
        
    }
}
