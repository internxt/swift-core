//
//  File.swift
//  
//
//  Created by Robert Garcia on 31/7/23.
//

import Foundation
import IDZSwiftCommonCrypto

struct KeyDerivation {
    func pbkdf2(password: String, salt: String, rounds: Int, derivedKeyLength: Int) -> [UInt8] {
        return PBKDF.deriveKey(password: password, salt: salt, prf: PBKDF.PseudoRandomAlgorithm.sha512, rounds: uint(rounds), derivedKeyLength: UInt(derivedKeyLength))
    }
    
    func pbkdf2(password: String, salt: [UInt8], rounds: Int, derivedKeyLength: Int) -> [UInt8] {
        return PBKDF.deriveKey(password: password, salt: salt, prf: PBKDF.PseudoRandomAlgorithm.sha512, rounds: uint(rounds), derivedKeyLength: UInt(derivedKeyLength))
    }
    
    func pbkdf2(password: String, salt: Data, rounds: Int, derivedKeyLength: Int) -> [UInt8] {
        
        var saltBytes = [UInt8](repeating: 0, count: salt.count)
        salt.copyBytes(to: &saltBytes, count: salt.count)
        return PBKDF.deriveKey(password: password, salt: saltBytes, prf: PBKDF.PseudoRandomAlgorithm.sha512, rounds: uint(rounds), derivedKeyLength: UInt(derivedKeyLength))
    }
    
}
