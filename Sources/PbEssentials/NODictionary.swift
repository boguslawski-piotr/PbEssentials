/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

// MARK: Non Optional Dictionary

public struct NODictionary<Key, Value>: Collection where Key: Hashable {
    public typealias Elements = Dictionary<Key, Value>
    public typealias Element = Elements.Element
    public typealias Index = Elements.Index
    
    public var keys: Elements.Keys { _elements.keys }
    public var values: Elements.Values { _elements.values }
    
    public var isEmpty: Bool { _elements.isEmpty }
    public var count: Int { _elements.count }
    
    public var _elements: Elements
    public let _default: Value
    
    @inlinable
    public init(_ elements: Elements, default value: Value) {
        self._elements = elements
        self._default = value
    }
    
    @inlinable
    public init(dictionaryLiteral elements: (Key, Value)..., default value: Value) {
        self._elements = Elements(uniqueKeysWithValues: elements)
        self._default = value
    }
    
    @inlinable
    public init<S>(uniqueKeysWithValues keysAndValues: S, default value: Value) where S: Sequence, S.Element == (Key, Value) {
        self._elements = Elements(uniqueKeysWithValues: keysAndValues)
        self._default = value
    }
    
    @inlinable
    public func contains(_ key: Key) -> Bool {
        _elements[key] != nil
    }
    
    @inlinable
    public subscript(key: Key) -> Value {
        get {
            return _elements[key] ?? _default
        }
        set {
            _elements[key] = newValue
        }
    }
    
    @inlinable @discardableResult public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? { _elements.updateValue(value, forKey: key) }
    @inlinable @discardableResult public mutating func moveValue(fromKey: Key, toKey: Key) -> Value? { _elements.moveValue(fromKey: fromKey, toKey: toKey) }
    @inlinable @discardableResult public mutating func removeValue(forKey key: Key) -> Value? { _elements.removeValue(forKey: key) }
    
    @inlinable public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> Dictionary<Key, T> { try _elements.mapValues(transform) }
    @inlinable public func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> Dictionary<Key, T> { try _elements.compactMapValues(transform) }
    
    @inlinable @discardableResult public mutating func remove(at index: Index) -> Element { _elements.remove(at: index) }
    @inlinable public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) { _elements.removeAll(keepingCapacity: keepCapacity) }
    
    public var startIndex: Index { _elements.startIndex }
    public var endIndex: Index { _elements.endIndex }
    
    @inlinable public func index(after i: Index) -> Index { _elements.index(after: i) }
    @inlinable public func index(forKey key: Key) -> Index? { _elements.index(forKey: key) }
    
    @inlinable public subscript(position: Index) -> Element { _elements[position] }
}

extension NODictionary: Equatable where Value: Equatable {}
extension NODictionary: Hashable where Value: Hashable {}
extension NODictionary: Encodable where Key: Encodable, Value: Encodable {}
extension NODictionary: Decodable where Key: Decodable, Value: Decodable {}

