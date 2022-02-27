/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

public protocol ErrorReportingIteratorProtocol: IteratorProtocol {
    var lastError: Error? { get }
}

public protocol ErrorReportingSequence: Sequence {
    var lastError: Error? { get }
}

public protocol ThrowingIteratorProtocol {
    /// The type of element traversed by the iterator.
    associatedtype Element

    /// Advances to the next element and returns it, or `nil` if no next element exists.
    mutating func nextThrows() throws -> Self.Element?
}

// MARK: Non Optional Dictionary

// TODO: make it a Collection

public struct KeyValue<Key, Value> where Key: Hashable {
    public var elements: [Key: Value] = [:]
    public let `default`: Value
    
    public init(default value: Value) {
        self.`default` = value
    }
    
    public subscript(key: Key) -> Value {
        get {
            return elements[key] ?? `default`
        }
        set {
            elements[key] = newValue
        }
    }
}

extension KeyValue: Equatable where Value: Equatable {}
extension KeyValue: Hashable where Value: Hashable {}

extension KeyValue: Encodable where Key: Encodable, Value: Encodable {}
extension KeyValue: Decodable where Key: Decodable, Value: Decodable {}

// MARK: Set

public extension Set {
    mutating func removeAll(where shouldBeRemoved: (Element) throws -> Bool) rethrows {
        while let element = try first(where: shouldBeRemoved) {
            remove(element)
        }
    }
    
    mutating func replaceAll(where shouldBeReplaced: (Element) throws -> Bool, with replacement: Element) rethrows {
        while let element = try first(where: shouldBeReplaced) {
            remove(element)
            insert(replacement)
        }
    }

    mutating func replaceAll(where shouldBeReplaced: (Element) throws -> Bool, with replacement: (Element) throws -> Element) rethrows {
        while let element = try first(where: shouldBeReplaced) {
            remove(element)
            insert(try replacement(element))
        }
    }
}

