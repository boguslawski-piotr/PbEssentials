/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

// MARK: Protocols

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

// MARK: Set

public extension Set {
    mutating func removeAll(where shouldBeRemoved: (Element) throws -> Bool) rethrows {
        while let element = try first(where: shouldBeRemoved) {
            remove(element)
        }
    }
    
    mutating func replaceAll(where shouldBeReplaced: (Element) throws -> Bool, with replacement: (Element) throws -> Element) rethrows {
        while let element = try first(where: shouldBeReplaced) {
            remove(element)
            insert(try replacement(element))
        }
    }
}

// MARK: Dictionary

public extension Dictionary {
    @discardableResult
    mutating func moveValue(fromKey: Key, toKey: Key) -> Value? {
        self[toKey] = self[fromKey]
        self.removeValue(forKey: fromKey)
        return self[toKey]
    }
}
