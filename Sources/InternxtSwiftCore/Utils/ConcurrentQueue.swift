//
//  ConcurrentQueue.swift
//
//
//  Created by Robert Garcia on 22/11/23.
//

import Foundation

@available(macOS 10.15, *)
class ConcurrentQueue {
    public let queue: DispatchQueue
    private let semaphore: DispatchSemaphore

    init(maxConcurrentOperations: Int) {
        self.queue = DispatchQueue(label: "com.InternxtSwiftCore.concurrentQueue", attributes: .concurrent)
        self.semaphore = DispatchSemaphore(value: maxConcurrentOperations)
    }
    
    func addOperation(_ block: @escaping () async throws -> Void) {
        queue.async {
            self.semaphore.wait()
            Task{
                do {
                    try await block()
                    self.semaphore.signal()
                } catch {
                    self.semaphore.signal()
                    throw error
                }
            }
            
        }
    }
}
