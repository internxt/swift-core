//
//  TrashTypes.swift
//  
//
//  Created by Robert Garcia on 7/8/23.
//

import Foundation


public struct AddItemsToTrashEndpoint: Endpoint {
    var body: Data?
    let method: HTTPMethod =  HTTPMethod.POST
    let path: String
    init(path: String, body: Data?) {
        self.path = path
        self.body = body
    }
}

public enum ItemToTrashType: String {
    case File = "file"
    case Folder = "folder"
}

public struct ItemToTrash: Encodable {
    public let id: Int
    public let type: String
    
    public init(id: Int, type: ItemToTrashType) {
        self.id = id
        self.type = type.rawValue
    }
}

public struct AddItemsToTrashPayload: Encodable {
    private let items: Array<ItemToTrash>
    
    public init(items: Array<ItemToTrash>) {
        self.items = items
    }
}

public struct AddItemsToTrashResponse: Decodable {
    
}