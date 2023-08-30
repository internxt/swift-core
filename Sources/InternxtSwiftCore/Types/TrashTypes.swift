//
//  TrashTypes.swift
//  
//
//  Created by Robert Garcia on 7/8/23.
//

import Foundation


public enum ItemToTrashType: String {
    case File = "file"
    case Folder = "folder"
}

public struct AddFilesToTrashPayload: Encodable {
    public let items: Array<FileToTrash>
    public init(items: Array<FileToTrash>) {
        self.items = items
    }
}
public struct FileToTrash: Encodable {
    public let id: String
    public let type: String
    
    public init(id: String) {
        self.id = id
        self.type = ItemToTrashType.File.rawValue
    }
}


public struct AddFoldersToTrashPayload: Encodable {
    public let items: Array<FolderToTrash>
    public init(items: Array<FolderToTrash>) {
        self.items = items
    }
}
public struct FolderToTrash: Encodable {
    public let id: Int
    public let type: String
    
    public init(id: Int) {
        self.id = id
        self.type = ItemToTrashType.Folder.rawValue
    }
}


public struct AddItemsToTrashResponse: Decodable {}
