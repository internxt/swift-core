//
//  Sequence.swift
//  
//
//  Created by Robert Garcia on 21/6/24.
//

import Foundation
extension Sequence {
    func asyncForEach(
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
}
