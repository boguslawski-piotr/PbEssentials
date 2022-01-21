/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

// MARK: PbValueWithLock

public struct PbValueWithLock<Value>
{
    public var valueWithoutLock : Value
    public let lock = NSRecursiveLock()
    public var value : Value {
        get {
            lock.lock()
            let v = valueWithoutLock
            lock.unlock()
            return v
        }
        set {
            lock.lock()
            valueWithoutLock = newValue
            lock.unlock()
        }
    }
    
    public init(_ value : Value) {
        self.valueWithoutLock = value
    }
    
    public func callAsFunction() -> Value {
        value
    }

    public mutating func callAsFunction(_ value : Value) {
        self.value = value
    }
}

// MARK: PbWithLock property wrapper

@propertyWrapper
public struct PbWithLock<Value>
{
    public var valueWithoutLock : Value
    public let lock = NSRecursiveLock()
    public var value : Value {
        get {
            lock.lock()
            let v = valueWithoutLock
            lock.unlock()
            return v
        }
        set {
            lock.lock()
            valueWithoutLock = newValue
            lock.unlock()
        }
    }

    public var projectedValue : NSRecursiveLock { lock }
    public var wrappedValue : Value {
        get { value }
        set { value = newValue }
    }
    
    public init(wrappedValue : Value) {
        self.valueWithoutLock = wrappedValue
    }
}

// MARK: NSLock / NSRecursiveLock Extensions

public extension NSRecursiveLock
{
    @inlinable
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        self.lock()
        defer {
            self.unlock()
        }
        return try body()
    }
}
