//
//  CoreConfigLoader.swift
//  
//
//  Created by Robert Garcia on 1/8/23.
//

import Foundation



public struct Config {
    public var DRIVE_URL: String
    public var NETWORK_URL: String
}
var loadedConfig: Mirror? = nil


public struct CoreConfigLoader {
    func load(config: Config) {
        loadedConfig = Mirror(reflecting: config)
    }
    
    func getConfigProperty(configKey: String) throws -> String {
        if(loadedConfig == nil) {
            throw ConfigLoaderError.NoConfigLoaded("There's no config loaded yet, call load() method first")
        }
        
        let configPropertyValue = loadedConfig?.children.first(where: { $0.label == configKey })
        
        if(configPropertyValue == nil) {
            throw ConfigLoaderError.MissingConfigProperty("Key \(configKey) was not found in the loaded config")
        }
        
        return configPropertyValue?.value as! String
    }
}
