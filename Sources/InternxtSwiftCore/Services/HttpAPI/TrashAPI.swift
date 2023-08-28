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
        self.apiClient = APIClient(urlSession: URLSession.shared, authorizationHeaderValue: "Bearer \(authToken)")
    }
    
    
    public func trashFiles(itemsToTrash: Array<FileToTrash>, debug: Bool = false) async throws -> Bool {
        let endpoint = Endpoint(path: "\(self.baseUrl)/storage/trash/add",method: .POST, body:  AddFilesToTrashPayload(items: itemsToTrash).toJson())
        
        do {
            _ = try await apiClient.fetch(type: AddItemsToTrashResponse.self, endpoint, debugResponse: debug)
            
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
    
    
    public func trashFolders(itemsToTrash: Array<FolderToTrash>, debug: Bool = false) async throws -> Bool {
        let endpoint = Endpoint(path: "\(self.baseUrl)/storage/trash/add",method: .POST, body: AddFoldersToTrashPayload(items: itemsToTrash).toJson())
        
        do {
            _ = try await apiClient.fetch(type: AddItemsToTrashResponse.self, endpoint, debugResponse: debug)
            
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
