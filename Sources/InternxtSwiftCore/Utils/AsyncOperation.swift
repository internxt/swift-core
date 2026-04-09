//
//  File.swift
//  
//
//  Created by Patricio Tovar on 8/1/25.
//

import Foundation

class AsyncOperation: Operation {
    private let lockQueue = DispatchQueue(label: "com.Internxt.SwiftCore.AsyncOperation", attributes: .concurrent)
    private var _isExecuting: Bool = false
    private var _isFinished: Bool = false
    
    override var isAsynchronous: Bool { true }
    
    override var isExecuting: Bool {
        get { lockQueue.sync { _isExecuting } }
        set {
            willChangeValue(forKey: "isExecuting")
            lockQueue.async(flags: .barrier) { self._isExecuting = newValue }
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    override var isFinished: Bool {
        get { lockQueue.sync { _isFinished } }
        set {
            willChangeValue(forKey: "isFinished")
            lockQueue.async(flags: .barrier) { self._isFinished = newValue }
            didChangeValue(forKey: "isFinished")
        }
    }
    
    func completeOperation() {
        isExecuting = false
        isFinished = true
    }
    
    override func start() {
        if isCancelled {
            completeOperation()
            return
        }
        isExecuting = true
        main()
    }
}
