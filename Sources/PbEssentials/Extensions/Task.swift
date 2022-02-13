/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

public extension Task
{
    typealias NoResultNoError = Task<Void, Never>
    typealias NoResultCanThrow = Task<Void, Error>
}

public extension Task where Success == Never, Failure == Never
{
    static func sleep(for ti : TimeInterval) async throws {
        try await sleep(nanoseconds: UInt64(ti * 1_000_000_000.0))
    }
}

public extension Task where Failure == Error
{
    static func delayed(by ti : TimeInterval, priority : TaskPriority? = nil,
                        @_implicitSelfCapture operation : @escaping @Sendable () async throws -> Success) -> Task {
        Task(priority: priority) {
            try await Task<Never, Never>.sleep(for: ti)
            return try await operation()
        }
    }
}
