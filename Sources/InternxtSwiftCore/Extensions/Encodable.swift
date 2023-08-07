//
//  Encodable.swift
//  
//
//  Created by Robert Garcia on 7/8/23.
//

import Foundation

extension Encodable {
    
    func toJson() -> Data? {
        do {
            return try JSONEncoder().encode(self)
        } catch {
          
            return nil
        }
    }
}
