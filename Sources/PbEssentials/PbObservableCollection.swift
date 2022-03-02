/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Combine
import Foundation

// TODO: dodac lock(s), opcje dla elements

@propertyWrapper
public final class PbObservableCollection<Elements: Collection>: PbObservableObjectBase where Elements.Element: PbObservableObject {
    public var wrappedValue: Elements {
        get { _elements }
        set {
            objectWillChange.send()
            _elements = newValue
            objectDidChange.send()
            cancelSubscriptions()
            resendChangesFromElements()
        }
    }
    
    public init(wrappedValue: Elements) {
        self._elements = wrappedValue
        super.init()
        resendChangesFromElements()
    }

    public var _elements: Elements

    func resendChangesFromElements() {
        for element in _elements {
            resendChanges(in: element)
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

