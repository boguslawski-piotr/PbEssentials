import Foundation
import System

// MARK: Debug tools

#if DEBUG
public func dbg(_ items: Any..., function : String = #function, file : String = #file, line : Int = #line) {
    let file = file.split(separator: "/").last ?? ""
    print("DBG:", "\(file)(\(line)): \(function):", "", terminator: "")
    items.forEach() { item in print(item, "", terminator: "") }
    print(terminator: "\n")
}
#else
@inlinable
public func dbg(_ items: Any...) {}
#endif

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
