/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation
import Combine

// MARK: PbObservableCollection

public protocol PbObservableCollection: Collection, PbObservableObject
where SubSequence == Elements.SubSequence,
      Indices == Elements.Indices,
      Index == Elements.Index,
      Iterator == Elements.Iterator,
      ObjectWillChangePublisher == ObservableObjectPublisher,
      ObjectDidChangePublisher == ObservableObjectPublisher
{
    associatedtype Elements: Collection where Elements.Element: PbObservableObject
    
    var _subscriptions : [AnyCancellable?] { get set }
    var _elements : Elements { get set }
    var elements : Elements { get set }
}

public extension PbObservableCollection
{
    func cancelSubscriptions() {
        _subscriptions.enumerated().forEach({
            $0.element?.cancel()
            _subscriptions[$0.offset] = nil
        })
        _subscriptions.removeAll()
    }
    
    var elements : Elements {
        get {
            _elements
        }
        set {
            objectWillChange.send()
            _elements = newValue
            objectDidChange.send()

            cancelSubscriptions()
            for element in _elements {
                _subscriptions.append(element.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() })
                _subscriptions.append(element.objectDidChange.sink { [weak self] _ in self?.objectDidChange.send() })
            }
        }
    }
}

public extension PbObservableCollection where Elements: Encodable, Element: Encodable
{
    func encode(to encoder: Encoder) throws {
        try elements.encode(to: encoder)
    }
}

extension PbObservableCollection
{
    public var startIndex: Index { elements.startIndex }
    public var endIndex: Index { elements.endIndex }
    public var indices: Indices { elements.indices }
    
    public subscript(bounds: Range<Index>) -> SubSequence { elements[bounds] }
    public subscript(position: Index) -> Element { elements[position] }
    
    public func index(after i: Index) -> Index { elements.index(after: i) }
    public func formIndex(after i: inout Index) { elements.formIndex(after: &i) }
    
    public __consuming func makeIterator() -> Iterator { elements.makeIterator() }
}

// MARK: PbObservableRandomAccessCollection

public protocol PbObservableRandomAccessCollection: PbObservableCollection, RandomAccessCollection
where Elements: RandomAccessCollection
{}

extension PbObservableRandomAccessCollection
{
    public func index(before i: Index) -> Index { elements.index(before: i) }
    public func formIndex(before i: inout Index) { elements.formIndex(before: &i) }
    public func index(after i: Index) -> Index { elements.index(after: i) }
    public func formIndex(after i: inout Index) { elements.formIndex(after: &i) }
    
    public func index(_ i: Index, offsetBy distance: Int) -> Index { elements.index(i, offsetBy: distance) }
    public func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? { elements.index(i, offsetBy: distance, limitedBy: limit) }

    public func distance(from start: Index, to end: Index) -> Int { elements.distance(from: start, to: end) }
}

// MARK: PbObservableCollectionBase

public class PbObservableCollectionBase
{
    public var _subscriptions : [AnyCancellable?] = []
}

// MARK: PbObservableArray

public final class PbObservableArray<Element>: PbObservableCollectionBase, PbObservableRandomAccessCollection where Element: PbObservableObject
{
    public typealias Element = Array<Element>.Element
    public typealias Index = Array<Element>.Index
    public typealias SubSequence = Array<Element>.SubSequence
    public typealias Indices = Array<Element>.Indices
    public typealias Iterator = IndexingIterator<[Element]>
    
    public var _elements : Array<Element> = []
    
    public override init() {}
    
    deinit {
        cancelSubscriptions()
    }
}

extension PbObservableArray: Decodable where Element: Decodable
{
    public convenience init(from decoder: Decoder) throws {
        self.init()
        elements = try Array<Element>(from: decoder)
    }
}

extension PbObservableArray: Encodable where Element: Encodable
{}

extension PbObservableArray
{
    // TODO: basic Array pass-through methods
}

// MARK: PbObservableSet

public final class PbObservableSet<Element>: PbObservableCollectionBase, PbObservableCollection where Element: PbObservableObject, Element: Hashable
{
    public typealias Element = Set<Element>.Element
    public typealias Index = Set<Element>.Index
    public typealias SubSequence = Set<Element>.SubSequence
    public typealias Indices = Set<Element>.Indices
    public typealias Iterator = Set<Element>.Iterator
    
    public var _elements : Set<Element> = []
    
    public override init() {}
    
    deinit {
        cancelSubscriptions()
    }
}

extension PbObservableSet: Decodable where Element: Decodable
{
    public convenience init(from decoder: Decoder) throws {
        self.init()
        elements = try Set<Element>(from: decoder)
    }
}

extension PbObservableSet: Encodable where Element: Encodable
{}

extension PbObservableSet
{
    // TODO: basic Set pass-through methods
}
