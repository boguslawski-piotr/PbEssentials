/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

extension Task {
    public typealias NoResultNoError = Task<Void, Never>
    public typealias NoResultCanThrow = Task<Void, Error>
}

extension Task where Success == Never, Failure == Never {
    public static func sleep(for ti: TimeInterval) async throws {
        try await sleep(nanoseconds: UInt64(ti * 1_000_000_000.0))
    }
}

extension Task where Failure == Error {
    public static func delayed(
        by ti: TimeInterval,
        priority: TaskPriority? = nil,
        @_implicitSelfCapture operation: @escaping @Sendable () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            try await Task<Never, Never>.sleep(for: ti)
            return try await operation()
        }
    }
}
