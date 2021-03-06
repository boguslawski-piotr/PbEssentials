/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation
import System

// MARK: Logging tools

public enum PbLogger {}

private var _lock = NSRecursiveLock()

private func processItem(_ item: Any) -> Any {
    if let error = item as? Error {
        return error.localizedDescription
    }
    return item
}

#if DEBUG

    public func dbg(level: Int = 0, _ items: Any..., function: String = #function, file: String = #fileID, line: Int = #line) {
        _lock.withLock {
            print("DBG" + (level == 0 ? ":" : "\(level):"), "\(file)(\(line)): \(function):", "", terminator: "")
            items.forEach { item in print(item, "", terminator: "") }
            print(terminator: "\n")
        }
    }
    
    extension PbLogger {
        public static func log(level: Int = 0, _ items: Any..., function: String = #function, file: String = #fileID, line: Int = #line) {
            _lock.withLock {
                print("LOG:" + (level == 0 ? ":" : "\(level):"), "\(file)(\(line)): \(function):", "", terminator: "")
                items.forEach { item in print(processItem(item), "", terminator: "") }
                print(terminator: "\n")
            }
        }
    }

#else

    @inlinable
    public func dbg(level: Int = 0, _ items: Any...) {}

    extension PbLogger {
        @inlinable
        public static func log(level: Int = 0, _ items: Any..., function: String = #function) {
            #warning("TODO: implement log for release builds")
        }
    }

#endif

// MARK: Mockup cipher

@available(*, deprecated, message: "Debug tool. Do NOT use in production code!")
public struct PbMockupCipher: PbCipher {
    public func encrypt<T>(data: T) throws -> Data where T: DataProtocol { Data(data) }
    public func decrypt<T>(data: T) throws -> Data where T: DataProtocol { Data(data) }
}

// MARK: Async / Await helpers

extension Task where Failure == Error {
    @available(*, deprecated, message: "Debug tool. Do NOT use in production code!")
    public static func blocking(
        priority: TaskPriority? = nil,
        timeout ti: TimeInterval = .infinity,
        @_implicitSelfCapture operation: @escaping @Sendable () async throws -> Success
    ) throws -> Success {
        return try BlockingTask<Success, Failure>().execute(priority, ti, operation)
    }
}

private class BlockingTask<Success, Failure: Error> {
    private var value: Success?
    private var error: Failure?
}

extension BlockingTask where Failure == Error {
    fileprivate func execute(_ priority: TaskPriority?, _ timeout: TimeInterval, _ operation: @escaping @Sendable () async throws -> Success) throws -> Success
    {
        let semaphore = DispatchSemaphore(value: 0)
        let task = Task<Success, Failure>(priority: priority) {
            defer {
                semaphore.signal()
            }
            do {
                let value = try await operation()
                self.value = value
                return value
            } catch {
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
