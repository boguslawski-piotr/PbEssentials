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
