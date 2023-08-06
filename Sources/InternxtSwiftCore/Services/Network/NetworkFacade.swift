//
//  File.swift
//  
//
//  Created by Robert Garcia on 4/8/23.
//

import Foundation

public struct NetworkFacade {
    private let apiUrl: String
    private let bridgeUser: String
    init(apiUrl: String , bridgeUser: String, userId: String) {
        self.apiUrl = apiUrl
        self.bridgeUser = bridgeUser
    }
}
