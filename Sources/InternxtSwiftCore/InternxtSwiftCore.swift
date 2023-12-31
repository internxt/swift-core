/**
 * Initialize the InternxtSwiftCore package with the given config
 */
public struct InternxtSwiftCore {
    
    public func initialize(config: Config) {
        CoreConfigLoader().load(config: config)
    }
}
