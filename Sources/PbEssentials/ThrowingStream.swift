/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

/// A synchronous sequence generated from an error-throwing closure
/// partialy compatible with AsyncThrowingStream but for synchronous
/// environment.
///
/// Example:
///
///     var sequence = ThrowingStream<T> {
///         /* code producing data (elements of type T) or
///            nil when sequence should end */
///     }
///
///     // use thrownig mode
///     while let element = try sequence.nextThrows() {
///         /* code consuming data */
///     }
///
///     // use normal mode (standard library does not
///     // support try/catch in sequences :()
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
    
    /// Constructs a synchronous throwing stream from a given element-producing closure `produce`.
    public init(unfolding produce: @escaping () throws -> Element?) where Failure == Error {
        self.produce = produce
    }
    
    public mutating func nextThrows() throws -> Element? {
        do {
            return try produce()
        }
        catch {
            lastError = error
            throw error
        }
    }
    
    public mutating func next() -> Element? {
        return try? nextThrows()
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
