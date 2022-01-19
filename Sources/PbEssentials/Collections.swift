import Foundation

public protocol ThrowingIteratorProtocol
{
    associatedtype Element
    mutating func nextThrows() throws -> Self.Element?
}

public struct ThrowingStream<Element, Failure> : Sequence, IteratorProtocol, ThrowingIteratorProtocol where Failure : Error
{
    private var produce : () throws -> Element?
    
    public init(unfolding produce: @escaping () throws -> Element?) where Failure == Error {
        self.produce = produce
    }
    
    public func nextThrows() throws -> Element? {
        do {
            return try produce()
        }
        catch {
            dbg(error)
            throw error
        }
    }
    
    public func next() -> Element? {
        return try? nextThrows()
    }

    public struct Iterator : IteratorProtocol, ThrowingIteratorProtocol
    {
        let stream : ThrowingStream<Element, Failure>
        
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
