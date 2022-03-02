/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Combine
import Foundation

// TODO: dodac lock(s), opcje dla dictionary

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
            resendChangesFromValues()
        }
    }
    
    public init(wrappedValue: Dictionary) {
        self._dictionary = wrappedValue
        super.init()
        resendChangesFromValues()
    }
    
    public var _dictionary: Dictionary
    
    func resendChangesFromValues() {
        for (_, value) in _dictionary {
            resendChanges(in: value)
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
