/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Combine
import Foundation

// MARK: PbOperationBase

open class PbOperationBase: BlockOperation, Identifiable {
    public struct Options: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        static let executeFinishedWhenAllBlocksAreFinished = Options(rawValue: 1 << 0)
    }

    public let launcher: UsesOperations
    public var options: Options = []
    public var stringId: String { String(id.hashValue) }
    
    public init(for sender: UsesOperations) {
        self.launcher = sender
        super.init()
        name = stringId
    }
}

// MARK: PbOperation

open class PbOperation<T>: PbOperationBase {
    public typealias Result = (name: String, result: T)
    public typealias Exception = (name: String, error: Error)

    @PbWithLock public var results: [Result] = []

    override open func start() {
        results = []
        canStart()
        super.start()
    }

    private var canStartCode: ((_ op: PbOperation) -> Bool)? = nil

    open func canStart() {
        guard canStartCode != nil else { return }
        launcher.execute {
            if !(self.canStartCode?(self) ?? true) {
                self.cancel()
            }
        }
    }

    open func canStart(code: @escaping (_ op: PbOperation) -> Bool) -> PbOperation {
        canStartCode = code
        return self
    }

    override open func main() {
        super.main()
        executeFinished(nil)
        cleanup()
    }

    private var cleanupCode: ((_ op: PbOperation) -> Void)? = nil

    open func cleanup() {
        launcher.execute {
            self.cleanupCode?(self)
            self.deInit()
        }
    }

    open func cleanup(code: @escaping (_ op: PbOperation) -> Void) -> PbOperation {
        cleanupCode = code
        return self
    }

    private var uniqueName: String {
        UUID().uuidString
    }

    public func block(code: @escaping (_ op: PbOperation) throws -> T) -> PbOperation {
        return block(uniqueName, code: code)
    }

    open func block(_ name: String, code: @escaping (_ op: PbOperation) throws -> T) -> PbOperation {
        addExecutionBlock {
            do {
                let result = (name, try code(self))
                self.executeFinished(result)
            } catch {
                self.executeThrown((name, error))
            }
        }
        return self
    }

    private let maxiumTimeToWaitForBlockToRespondToCancellation = TimeInterval(1.0)

    public func asyncBlock(code: @escaping (_ op: PbOperation) async throws -> T) -> PbOperation {
        asyncBlock(uniqueName, code: code)
    }

    open func asyncBlock(_ name: String, code: @escaping (_ op: PbOperation) async throws -> T) -> PbOperation {
        addExecutionBlock {
            do {
                let semaphore = DispatchSemaphore(value: 0)
                let task = Task<Void, Never> {
                    defer {
                        semaphore.signal()
                    }
                    do {
                        let result = (name, try await code(self))
                        self.executeFinished(result)
                    } catch {
                        self.executeThrown((name, error))
                    }
                }

                var canceledAt = Date.distantPast
                while true {
                    if semaphore.wait(timeout: .now() + .miliseconds(1)) == .timedOut {
                        if self.isCancelled {
                            // Just a guard for these blocks that do not check cancellation status :(
                            if canceledAt == Date.distantPast {
                                task.cancel()
                                canceledAt = Date()
                            } else if canceledAt.distance(to: Date()) > self.maxiumTimeToWaitForBlockToRespondToCancellation {
                                throw CancellationError()
                            }
                        }
                        continue
                    }
                    break
                }
            } catch {
                self.executeThrown((name, error))
            }
        }
        return self
    }

    private var methods: Set<String> = []

    public func execute(code: @escaping () throws -> Void) {
        execute(uniqueName, code: code)
    }

    open func execute(_ name: String, code: @escaping () throws -> Void) {
        launcher.messages.read(name) { _ in
            do {
                try code()
            } catch {
                self.executeThrown((name, error))
            }
        }
        launcher.messages.send(name, data: nil)
    }

    open func execute(_ name: String, data: Any? = nil) {
        assert(methods.contains(name))
        launcher.messages.send(name + stringId, data: data)
    }

    public func method(_ name: String, code: @escaping () throws -> Void) -> PbOperation {
        return method(name) { (_: Any?) in try code() }
    }

    open func method<T>(_ name: String, code: @escaping (T) throws -> Void) -> PbOperation {
        assert(!methods.contains(name))
        if methods.insert(name).inserted {
            launcher.messages.subscribe(to: name + stringId) { data in
                do {
                    try code(data as! T)
                } catch {
                    self.executeThrown((name, error))
                }
            }
        }
        return self
    }

    private lazy var executeFinished = "finished" + stringId
    private var finishedBlocks = 0

    private func executeFinished(_ result: Result?) {
        if result != nil {
            $results.withLock {
                results.append(result!)
            }
            if finishedBlocks > 0 && !options.contains(.executeFinishedWhenAllBlocksAreFinished) {
                launcher.messages.send(executeFinished, data: result)
            }
        } else {
            if finishedBlocks > 0 && options.contains(.executeFinishedWhenAllBlocksAreFinished) {
                for result in results {
                    launcher.messages.send(executeFinished, data: result)
                }
            }

        }
    }

    public func finished(code: @escaping () -> Void) -> PbOperation {
        return finished { _ in code() }
    }

    public func finished(code: @escaping (T) -> Void) -> PbOperation {
        return finished { (_, result) in code(result) }
    }

    open func finished(code: @escaping (String, T) -> Void) -> PbOperation {
        launcher.messages.subscribe(to: executeFinished) { data in
            let data = data as! Result
            code(data.name, data.result)
        }
        finishedBlocks += 1
        return self
    }

    private lazy var executeThrown = "thrown" + stringId
    private var thrownBlocks = 0

    private func executeThrown(_ data: Exception) {
        guard thrownBlocks > 0 else { return }
        launcher.messages.send(executeThrown, data: data)
    }

    public func thrown(code: @escaping (Error) -> Void) -> PbOperation {
        return thrown { (_, error) in code(error) }
    }

    open func thrown(code: @escaping (String, Error) -> Void) -> PbOperation {
        launcher.messages.subscribe(to: executeThrown) { data in
            let data = data as! Exception
            code(data.name, data.error)
        }
        thrownBlocks += 1
        return self
    }

    public func dependsOn(_ op: Operation?) -> PbOperation {
        if op != nil {
            self.addDependency(op!)
        }
        return self
    }

    public func qualityOfService(_ qualityOfService: QualityOfService) -> PbOperation {
        self.qualityOfService = qualityOfService
        return self
    }

    public func queuePriority(_ queuePriority: PbOperation.QueuePriority) -> PbOperation {
        self.queuePriority = queuePriority
        return self
    }

    public func options(_ options: Options) -> PbOperation {
        self.options = options
        return self
    }

    open func deInit() {
        launcher.messages.cancelSubscriptions(for: [executeFinished, executeThrown])
        finishedBlocks = 0
        thrownBlocks = 0
        if methods.count > 0 {
            launcher.messages.cancelSubscriptions(for: methods.compactMap({ return $0 + stringId }))
            methods = []
        }
    }

    deinit {
        deInit()
    }
}

// MARK: UsesOperations

open class UsesOperations: Identifiable {
    public lazy var operationQueue1 = operationQueueWithUpTo(threads: 1)
    public lazy var operationQueue = OperationQueue()
    public lazy var messages = PbMessages(self)
    
    open func operationQueueWithUpTo(threads: Int) -> OperationQueue {
        let oq = OperationQueue()
        oq.maxConcurrentOperationCount = threads
        return oq
    }
    
    open func operation<T>() -> PbOperation<T> {
        return PbOperation<T>(for: self)
    }

    open func operation<T>(code: @escaping (_ op: PbOperation<T>) throws -> T) -> PbOperation<T> {
        return PbOperation<T>(for: self).block("_", code: { op in try code(op) })
    }

    open func asyncOperation<T>(code: @escaping (_ op: PbOperation<T>) async throws -> T) -> PbOperation<T> {
        return PbOperation<T>(for: self).asyncBlock("_", code: { op in try await code(op) })
    }

    /// A convenient procedure that allows you to execute a piece of code on the main thread of the program, no matter what thread you are currently on.
    public func execute(_ code: @escaping () -> Void) {
        let name = UUID().uuidString
        messages.read(name, from: self) { _ in code() }
        messages.send(name)
    }

    public func execute(_ code: @escaping () throws -> Void) throws {
        let name = UUID().uuidString
        var err: Error?
        messages.read(name, from: self) { _ in
            do { try code() } catch { err = error }
        }
        messages.send(name)
        if err != nil {
            throw err!
        }
    }

    public func execute<T>(with data: T, _ code: @escaping (T) -> Void) {
        let name = UUID().uuidString
        messages.read(name, from: self) { data in code(data as! T) }
        messages.send(name, data: data)
    }

    public func execute<T>(with data: T, _ code: @escaping (T) throws -> Void) throws {
        let name = UUID().uuidString
        var err: Error?
        messages.read(name, from: self) { data in
            do { try code(data as! T) } catch { err = error }
        }
        messages.send(name, data: data)
        if err != nil {
            throw err!
        }
    }
}

// MARK: Basic tests

public class UsesOperationsTests: UsesOperations {
    struct SomeData {
        var name: String
        var data: Int
    }

    public func test1() {

        execute {
            dbg("execute test, from main thread")
        }

        // simple operation

        operationQueue1 += operation { op in
            dbg("simple")
        }

        // complex ;) operation

        let Test = String("test")
        let Test2 = String("test2")

        let oper = operation()
            .canStart { op in
                dbg("can start")
                return true
            }

            .block("first") { op -> SomeData? in
                dbg("first started, main thread:", Thread.isMainThread)
                op.execute(Test, data: 2.3)
                dbg("between test and test2 in first")
                op.execute(Test2)
                op.execute {
                    dbg("execute from first, main thread:", Thread.isMainThread)
                }
                dbg("first ended")
                return SomeData(name: "block(first)", data: 0)
            }
            .block("second") { op in
                dbg("second started")
                try op.sleep(for: .seconds(1))
                dbg("second ended")
                return SomeData(name: "block(second)", data: 1)
            }
            .block("third") { op in
                dbg("third started")
                throw PbError("third error!")
            }

            .asyncBlock("fourth (async)") { op in
                dbg("fourth (async) started")
                try await Task.sleep(nanoseconds: 4 * 1_000_000_000)
                dbg("fourth (async) ended")
                return nil
            }

            .method(Test) { (param: Double) in
                dbg("method test:", param, "main thread:", Thread.isMainThread)
            }
            .method(Test2) {
                dbg("method test2")
                throw PbError("test2")
            }

            .finished {
                dbg("general finished")
            }
            .finished { blockName, result in
                dbg(blockName, ": finished with result", result ?? "nil")
            }

            .thrown { blockOrMethodName, error in
                dbg(blockOrMethodName, ": thrown (on mainThread?: \(Thread.isMainThread)):", PbError(error).description)
            }

            .cleanup { op in
                dbg("this is a cleanup block")
            }

            .options([.executeFinishedWhenAllBlocksAreFinished])
            .qualityOfService(.userInitiated)

        operationQueue1
            + oper += operation { op in
                dbg("this should print at the very end, because queue is set to one thread")
            }

        Task {
            oper.waitUntilFinished()
            dbg("oper finished")
        }
    }
}
