import Foundation

public protocol ErrorReportingIteratorProtocol : IteratorProtocol
{
    var lastError : Error? { get }
}

public protocol ErrorReportingSequence : Sequence
{
    var lastError : Error? { get }
}

public protocol ThrowingIteratorProtocol
{
    /// The type of element traversed by the iterator.
    associatedtype Element
    
    /// Advances to the next element and returns it, or `nil` if no next element exists.
    mutating func nextThrows() throws -> Self.Element?
}

///
/// Usage:
///
///     var sequence = ThrowingStream<T> {
///         /* code producing data (elements of type T) */
///     }
///
/// full try/catch support:
///
///     while let element = try sequence.nextThrows() {
///         /* code consuming data */
///     }
///
/// handling errors manually:
///
///     for element in sequence {
///         /* code consuming data */
///     }
///     if let error = sequence.lastError {
///         throw error
///     }
///
public struct ThrowingStream<Element, Failure> : ErrorReportingSequence, ErrorReportingIteratorProtocol, ThrowingIteratorProtocol where Failure : Error
{
    private var produce : () throws -> Element?
    public private(set) var lastError : Error?

    public init(unfolding produce: @escaping () throws -> Element?) where Failure == Error {
        self.produce = produce
    }
    
    public mutating func nextThrows() throws -> Element? {
        return try produce()
    }
    
    public mutating func next() -> Element? {
        do {
            return try nextThrows()
        }
        catch {
            lastError = error
            return nil
        }
    }

    public struct Iterator : ErrorReportingIteratorProtocol, ThrowingIteratorProtocol
    {
        internal var stream : ThrowingStream<Element, Failure>
        public var lastError : Error? { stream.lastError }
        
        public mutating func nextThrows() throws -> Element? {
            try stream.nextThrows()
        }
        
        public mutating func next() -> Element? {
            stream.next()
        }
    }
    
    public __consuming func makeIterator() -> Iterator {
        Iterator(stream: self)
    }
}
