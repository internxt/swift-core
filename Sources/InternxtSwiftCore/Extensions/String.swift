//
//  String.swift
//  
//
//  Created by Robert Garcia on 31/7/23.
//

import Foundation


extension StringProtocol {
    var hex: [UInt8] {
        var startIndex = self.startIndex
        return (0..<count/2).compactMap { _ in
            let endIndex = index(after: startIndex)
            defer { startIndex = index(after: endIndex) }
            return UInt8(self[startIndex...endIndex], radix: 16)
        }
    }
    
    var isValidHex: Bool {
        filter(\.isHexDigit).count == count
    }
    
    
}
