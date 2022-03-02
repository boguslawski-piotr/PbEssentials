/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Combine
import Foundation

// TODO: dodac lock(s), opcje dla elements/dictionary

// MARK: PbObservableSequence

@propertyWrapper
public final class PbObservableCollection<Elements: Collection>: PbObservableObjectBase where Elements.Element: PbObservableObject {
    public var wrappedValue: Elements {
        get { _elements }
        set {
            objectWillChange.send()
            _elements = newValue
            objectDidChange.send()
            cancelSubscriptions()
            subscribeToElements()
        }
    }
    
    public init(wrappedValue: Elements) {
        self._elements = wrappedValue
        super.init()
        subscribeToElements()
    }

    public var _elements: Elements

    func subscribeToElements() {
        for element in _elements {
            subscribe(to: element)
        }
    }
}

extension PbObservableCollection: Encodable where Elements: Encodable, Elements.Element: Encodable {
    public func encode(to encoder: Encoder) throws {
        try _elements.encode(to: encoder)
    }
}

extension PbObservableCollection: Decodable where Elements: Decodable, Elements.Element: Decodable {
    public convenience init(from decoder: Decoder) throws {
        self.init(wrappedValue: try Elements(from: decoder))
    }
}

// MARK: PbObservableDictionary

@propertyWrapper
public final class PbObservableDictionary<Key, Value>: PbObservableObjectBase where Key: Hashable, Value: PbObservableObject {
    public typealias Dictionary = Swift.Dictionary<Key, Value>
    
    public var wrappedValue: Dictionary {
        get { _dictionary }
        set {
            objectWillChange.send()
            _dictionary = newValue
            objectDidChange.send()
            cancelSubscriptions()
            subscribeToValues()
        }
    }
    
    public init(wrappedValue: Dictionary) {
        self._dictionary = wrappedValue
        super.init()
        subscribeToValues()
    }
    
    public var _dictionary: Dictionary

    func subscribeToValues() {
        for (_, value) in _dictionary {
            subscribe(to: value)
        }
    }
    
}

extension PbObservableDictionary: Encodable where Dictionary.Key: Encodable, Dictionary.Value: Encodable {
    public func encode(to encoder: Encoder) throws {
        try _dictionary.encode(to: encoder)
    }
}

extension PbObservableDictionary: Decodable where Dictionary.Key: Decodable, Dictionary.Value: Decodable {
    public convenience init(from decoder: Decoder) throws {
        self.init(wrappedValue: try Dictionary(from: decoder))
    }
}
