//
//  CryptoUtils.swift
//  
//
//  Created by Robert Garcia on 31/7/23.
//

import Foundation
import IDZSwiftCommonCrypto

struct CryptoUtils {
    public func hexStringToBytes(_ hexString: String) -> [UInt8] {
        return arrayFrom(hexString: hexString)
    }
    
    public func bytesToHexString(_ bytes: [UInt8]) -> String {
        let format = "%02hhx"
        return bytes.map { String(format: format, $0) }.joined()
    }
}

