//
//  AESCipher.swift
//  
//
//  Created by Robert Garcia on 31/7/23.
//

import Foundation
import IDZSwiftCommonCrypto


class AESCipher {
    var utils = CryptoUtils()
    let bufferSize = 1024 * 8
    private func isValidIv(iv: [UInt8]) -> Bool {
        return StreamCryptor.Algorithm.aes.blockSize() == iv.count
    }
    
    // Encrypts an input stream to an output stream given a key and an IV
    // using AES256 CTR mode with No padding
    public func encryptFromStream(input: InputStream, output:OutputStream, key: [UInt8], iv: [UInt8] ,callback: (_:CryptoError?, _: Status?) -> Void ) -> Void {
            let algorithm = StreamCryptor.Algorithm.aes
            
            
            if !self.isValidIv(iv: iv) {
                return callback(CryptoError.badIv, nil)
            }
            
            
            let cryptStream = StreamCryptor(
                operation: StreamCryptor.Operation.encrypt,
                algorithm: algorithm,
                mode: StreamCryptor.Mode.CTR,
                padding: StreamCryptor.Padding.NoPadding,
                key: key,
                iv: iv
            )
            
            // Prepare buffers
            var inputBuffer = Array<UInt8>(repeating:0, count:bufferSize)
            var outputBuffer = Array<UInt8>(repeating:0, count:bufferSize)
            
            // Open streams
            input.open()
            output.open()
            
            var encryptedBytes  : Int = 0;
            while input.hasBytesAvailable {
                // Read the bytes
                let bytesRead = input.read(&inputBuffer, maxLength: inputBuffer.count);
                let status = cryptStream.update(bufferIn: inputBuffer, byteCountIn: bytesRead, bufferOut: &outputBuffer, byteCapacityOut: outputBuffer.count, byteCountOut: &encryptedBytes)
                
                if(status != Status.success) {
                    return callback(CryptoError.encryptionFailed, nil)
                }
                // Make sure status is Ok
                if(encryptedBytes > 0) {
                    let bytesOut = output.write(outputBuffer, maxLength: encryptedBytes)
                    assert(bytesOut == Int(encryptedBytes))
                }
                
            }
            
            // Final check
            let status = cryptStream.final(bufferOut: &outputBuffer, byteCapacityOut: outputBuffer.count, byteCountOut: &encryptedBytes)
            
            // Everything ok, close streams
            input.close()
            output.close();
            
            callback(nil,status)
        
        
    }
    
    
    // Decrypts an input stream to an output stream given a key and an IV
    // using AES256 CTR mode with No padding
    
    public func decryptFromStream(input: InputStream, output:OutputStream, key: [UInt8], iv: [UInt8], callback: (_:CryptoError?, _: Status?) -> Void ) -> Void {
   
        if !self.isValidIv(iv: iv) {
            return callback(CryptoError.badIv, nil)
        }
        
        
        let cryptStream = StreamCryptor(
            operation: StreamCryptor.Operation.decrypt,
            algorithm: StreamCryptor.Algorithm.aes,
            mode: StreamCryptor.Mode.CTR,
            padding: StreamCryptor.Padding.NoPadding,
            key:key,
            iv: iv
        )
        
        // Prepare buffers
        var inputBuffer = Array<UInt8>(repeating:0, count:bufferSize)
        var outputBuffer = Array<UInt8>(repeating:0, count:bufferSize)
        
        // Open streams
        input.open()
        output.open()
        
        var encryptedBytes  : Int = 0;
        while input.hasBytesAvailable {
            
            // Read the bytes
            let bytesRead = input.read(&inputBuffer, maxLength: inputBuffer.count);
            let status = cryptStream.update(bufferIn: inputBuffer, byteCountIn: bytesRead, bufferOut: &outputBuffer, byteCapacityOut: outputBuffer.count, byteCountOut: &encryptedBytes)
            
            if(status != Status.success) {
                return callback(CryptoError.decryptionFailed, nil)
            }
            if(encryptedBytes > 0) {
                let bytesOut = output.write(outputBuffer, maxLength: encryptedBytes)
                assert(bytesOut == Int(encryptedBytes))
            }
            
        }
        
        // Final check
        let status = cryptStream.final(bufferOut: &outputBuffer, byteCapacityOut: outputBuffer.count, byteCountOut: &encryptedBytes)
        
        // Close streams
        input.close()
        output.close()
        
        // All ok, notify via callback
        callback(nil,status)
    }
}
