/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

@propertyWrapper
public struct PbWithLock<Value>
{
    // MARK: Property wrapper
    
    public let projectedValue = NSRecursiveLock()
    public var wrappedValue : Value {
        get {
            lock.lock()
            let v = _value
            lock.unlock()
            return v
        }
        set {
            lock.lock()
            _value = newValue
            lock.unlock()
        }
    }

    public init(wrappedValue: Value) {
        self._value = wrappedValue
    }

    // MARK: Normal boxing structure
    
    public var lock : NSRecursiveLock { projectedValue }
    public var value : Value {
        get { wrappedValue }
        set { wrappedValue = newValue }
    }

    public init(_ value: Value) {
        self._value = value
    }

    private var _value : Value
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
