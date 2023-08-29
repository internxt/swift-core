//
//  URL.swift
//  
//
//  Created by Robert Garcia on 10/8/23.
//

import Foundation

extension URL {
    public var attributes: [FileAttributeKey : Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: path)
        } catch let error as NSError {
            print("FileAttribute error: \(error)")
        }
        return nil
    }

    public var fileSize: UInt64 {
        return attributes?[.size] as? UInt64 ?? UInt64(0)
    }
}
