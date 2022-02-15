/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Combine
import Foundation

// MARK: PbObservableCollection

public protocol PbObservableCollection: Collection, PbObservableObject where Element: PbObservableObject, Index == Elements.Index, Indices == Elements.Indices, Iterator == Elements.Iterator, SubSequence == Elements.SubSequence, ObjectWillChangePublisher == ObservableObjectPublisher, ObjectDidChangePublisher == ObservableObjectPublisher {
    associatedtype Elements: Collection

    var _subscriptions: [AnyCancellable?] { get set }
    var _elements: Elements { get set }
    var elements: Elements { get set }
}

extension PbObservableCollection {
    public func cancelSubscriptions() {
        _subscriptions.enumerated().forEach({
            $0.element?.cancel()
            _subscriptions[$0.offset] = nil
        })
        _subscriptions.removeAll()
    }

    public var elements: Elements {
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

extension PbObservableCollection {
    public var startIndex: Index { elements.startIndex }
    public var endIndex: Index { elements.endIndex }
    public var indices: Indices { elements.indices }

    public subscript(position: Index) -> Element { elements[position] }
    public subscript(bounds: Range<Index>) -> SubSequence { elements[bounds] }

    public func index(after i: Index) -> Index { elements.index(after: i) }

    public __consuming func makeIterator() -> Iterator { elements.makeIterator() }
}

extension PbObservableCollection where Elements: Encodable, Element: Encodable {
    public func encode(to encoder: Encoder) throws {
        try elements.encode(to: encoder)
    }
}

// MARK: PbObservableRandomAccessCollection

public protocol PbObservableRandomAccessCollection: PbObservableCollection, RandomAccessCollection where Elements: RandomAccessCollection {}

extension PbObservableRandomAccessCollection {
    public func index(before i: Index) -> Index { elements.index(before: i) }
    public func index(after i: Index) -> Index { elements.index(after: i) }

    public func distance(from start: Index, to end: Index) -> Int { elements.distance(from: start, to: end) }
}

// MARK: PbObservableCollectionBase

open class PbObservableCollectionBase {
    public var _subscriptions: [AnyCancellable?] = []
}

// MARK: PbObservableArray

public final class PbObservableArray<Element>: PbObservableCollectionBase, PbObservableRandomAccessCollection where Element: PbObservableObject {
    public typealias Element = Array<Element>.Element
    public typealias Index = Array<Element>.Index
    public typealias Indices = Array<Element>.Indices
    public typealias SubSequence = Array<Element>.SubSequence
    public typealias Iterator = IndexingIterator<[Element]>

    public var _elements: [Element] = []

    public override init() {}

    deinit {
        cancelSubscriptions()
    }
}

extension PbObservableArray: Decodable where Element: Decodable {
    public convenience init(from decoder: Decoder) throws {
        self.init()
        elements = try [Element](from: decoder)
    }
}

extension PbObservableArray: Encodable where Element: Encodable {}

extension PbObservableArray {
    // TODO: basic Array pass-through methods
}

// MARK: PbObservableSet

public final class PbObservableSet<Element>: PbObservableCollectionBase, PbObservableCollection where Element: PbObservableObject, Element: Hashable {
    public typealias Element = Set<Element>.Element
    public typealias Index = Set<Element>.Index
    public typealias Indices = Set<Element>.Indices
    public typealias SubSequence = Set<Element>.SubSequence
    public typealias Iterator = Set<Element>.Iterator

    public var _elements: Set<Element> = []

    public override init() {}

    deinit {
        cancelSubscriptions()
    }
}

extension PbObservableSet: Decodable where Element: Decodable {
    public convenience init(from decoder: Decoder) throws {
        self.init()
        elements = try Set<Element>(from: decoder)
    }
}

extension PbObservableSet: Encodable where Element: Encodable {}

extension PbObservableSet {
    // TODO: basic Set pass-through methods
}
