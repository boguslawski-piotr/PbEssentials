/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation
import System

// MARK: Logging tools

public enum PbLogger {}

fileprivate var _lock = NSRecursiveLock()

fileprivate func processItem(_ item : Any) -> Any {
    if let error = item as? Error {
        return error.localizedDescription
    }
    return item
}

#if DEBUG

public func dbg(_ items: Any..., function : String = #function, file : String = #fileID, line : Int = #line) {
    _lock.withLock {
        print("DBG:", "\(file)(\(line)): \(function):", "", terminator: "")
        items.forEach() { item in print(item, "", terminator: "") }
        print(terminator: "\n")
    }
}

public extension PbLogger
{
    static func log(_ items: Any..., function : String = #function, file : String = #fileID, line : Int = #line) {
        _lock.withLock {
            print("LOG:", "\(file)(\(line)): \(function):", "", terminator: "")
            items.forEach() { item in print(processItem(item), "", terminator: "") }
            print(terminator: "\n")
        }
    }
}

#else

@inlinable
public func dbg(_ items: Any...) {}

public extension PbLogger
{
    @inlinable
    static func log(_ items: Any..., function : String = #function) {
        #warning("TODO: implement log for release builds")
    }
}

#endif

// MARK: Mockup cipher

@available(*, deprecated, message: "Debug tool. Do NOT use in production code!")
public final class PbMockupCipher : PbCipher
{
    public init() {}
    
    private lazy var coder = JSONCoder()
    
    public func encrypt<T>(data: T) throws -> Data where T : DataProtocol {
        Data(data)
    }
    
    public func encrypt<T>(_ item: T) throws -> Data where T : Encodable {
        try coder.encode(item)
    }
    
    public func decrypt<T>(data: T) throws -> Data where T: DataProtocol {
        Data(data)
    }
    
    public func decrypt<T>(itemOf type: T.Type, from data: Data) throws -> T where T : Decodable {
        try coder.decode(type, from: data)
    }
}

// MARK: Async / Await helpers

public extension Task where Failure == Error
{
    @available(*, deprecated, message: "Debug tool. Do NOT use in production code!")
    static func blocking(priority : TaskPriority? = nil, timeout ti : TimeInterval = .infinity,
                         @_implicitSelfCapture operation : @escaping @Sendable () async throws -> Success) throws -> Success {
        return try BlockingTask<Success, Failure>().execute(priority, ti, operation)
    }
}

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
