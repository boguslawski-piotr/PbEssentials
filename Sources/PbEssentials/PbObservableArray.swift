/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation
import Combine

public final class PbObservableArray<Element>: PbObservableObject where Element: PbObservableObject
{
    public init() {}
    
    public var subscriptions : [AnyCancellable?] = []

    public var elements : Array<Element> = [] {
        willSet {
            objectWillChange.send()
            subscriptions.removeAll()
            for element in newValue {
                subscriptions.append(element.objectWillChange.sink { _ in self.objectWillChange.send() })
            }
        }
        didSet {
            objectDidChange.send()
            for element in elements {
                subscriptions.append(element.objectDidChange.sink { _ in self.objectDidChange.send() })
            }
        }
    }
}

// MARK: Encodable & Decodable conformance

extension PbObservableArray: Decodable where Element: Decodable
{
    public convenience init(from decoder: Decoder) throws {
        self.init()
        elements = try Array<Element>(from: decoder)
    }
}

extension PbObservableArray: Encodable where Element: Encodable
{
    public func encode(to encoder: Encoder) throws {
        try elements.encode(to: encoder)
    }
}

// MARK: RandomAccessCollection conformance

extension PbObservableArray: RandomAccessCollection
{
    public typealias SubSequence = Array<Element>.SubSequence
    public typealias Indices = Array<Element>.Indices
    public typealias Index = Array<Element>.Index
    public typealias Iterator = Array<Element>.Iterator
    
    public var startIndex: Index { elements.startIndex }
    public var endIndex: Index { elements.endIndex }
    public var indices: Indices { elements.indices }
    
    public subscript(bounds: Range<Index>) -> SubSequence { elements[bounds] }
    public subscript(position: Index) -> Element { elements[position] }
    
    public func index(before i: Index) -> Index { elements.index(before: i) }
    public func formIndex(before i: inout Index) { elements.formIndex(before: &i) }
    public func index(after i: Index) -> Index { elements.index(after: i) }
    public func formIndex(after i: inout Index) { elements.formIndex(after: &i) }
    
    public func index(_ i: Index, offsetBy distance: Int) -> Index { elements.index(i, offsetBy: distance) }
    public func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? { elements.index(i, offsetBy: distance, limitedBy: limit) }
    public func distance(from start: Index, to end: Index) -> Int { elements.distance(from: start, to: end) }
    
    public __consuming func makeIterator() -> Iterator { elements.makeIterator() }
    public func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R? { try elements.withContiguousStorageIfAvailable(body) }
}
