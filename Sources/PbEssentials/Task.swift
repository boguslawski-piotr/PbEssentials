//
//  Created by Piotr Boguslawski on 10/01/2022.
//

import Foundation
import System

// MARK: Task extensions

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

public extension Task where Failure == Never
{
    static func delayed(by ti : TimeInterval, priority : TaskPriority? = nil,
                        @_implicitSelfCapture operation : @escaping @Sendable () async -> Success) -> Task {
        Task(priority: priority) {
            try? await Task<Never, Never>.sleep(for: ti)
            return await operation()
        }
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
    
    @available(*, deprecated, message: "Do NOT use this helper in production code!")
    static func blocking(priority : TaskPriority? = nil, timeout ti : TimeInterval = .infinity,
                         @_implicitSelfCapture operation : @escaping @Sendable () async throws -> Success) throws -> Success {
        return try BlockingTask<Success, Failure>().execute(priority, ti, operation)
    }
}

// MARK: Private implementation

fileprivate class BlockingTask<Success, Failure : Error>
{
    private var value : Success?
    private var error : Failure?
}

fileprivate extension BlockingTask where Failure == Error
{
    func execute(_ priority : TaskPriority?, _ timeout : TimeInterval, _ operation : @escaping @Sendable () async throws -> Success) throws -> Success {
        let semaphore = DispatchSemaphore(value: 0)
        let task = Task<Success, Failure>(priority: priority) {
            defer {
                semaphore.signal()
            }
            do {
                let value = try await operation()
                self.value = value
                return value
            }
            catch {
                self.error = error
                throw error
            }
        }
        if semaphore.wait(timeout: .now() + timeout) == .timedOut {
            task.cancel()
            throw MachError(.operationTimedOut)
        }
        if self.error != nil {
            throw self.error!
        }
        return self.value!
    }
}
