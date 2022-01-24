/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Combine

/**
 A property that can report changes to the parent.
 
 The properties `_objectWillChange` and `_objectDidChange`should be declared
 but should never be initialized. Their initialization will take place automatically from
 the parent object (if it's an object that conforms to PbObservableObject).
 */
public protocol PbPublishedProperty
{
    /// Publisher for `willSet` events, in the parent observable object
    var _objectWillChange : ObservableObjectPublisher? { get nonmutating set }

    /// Publisher for `didSet` events, in the parent observable object.
    var _objectDidChange : ObservableObjectPublisher? { get nonmutating set }
}

@propertyWrapper
public final class PbPublished<Value> : PbPublishedProperty
{
    public var wrappedValue : Value {
        get { value }
        set {
            _objectWillChange?.send()
            valueWillChange.send(newValue)
            
            value = newValue
            
            valueDidChange.send(newValue)
            _objectDidChange?.send()

            valueDidSet?()
        }
    }

    public struct ValuePublicPublishers
    {
        public var willChange : AnyPublisher<Value, Never>
        public var didChange : AnyPublisher<Value, Never>
    }

    public lazy var projectedValue = ValuePublicPublishers(willChange: valueWillChange.eraseToAnyPublisher(),
                                                           didChange: valueDidChange.eraseToAnyPublisher())
    
    public init(wrappedValue: Value) {
        value = wrappedValue
    }

    public init(wrappedValue: Value) where Value: PbObservableObject {
        value = wrappedValue
        valueDidSet = { [weak self] in
            self?.cancelSubscriptions()
            self?.subscriptions[0] = self?.value.objectWillChange.sink { [weak self] _ in self?._objectWillChange?.send() }
            self?.subscriptions[1] = self?.value.objectDidChange.sink { [weak self] _ in self?._objectDidChange?.send() }
        }
        valueDidSet!()
    }

    public var _objectWillChange : ObservableObjectPublisher?
    public var _objectDidChange : ObservableObjectPublisher?

    private lazy var valueWillChange = CurrentValueSubject<Value, Never>(value)
    private lazy var valueDidChange = CurrentValueSubject<Value, Never>(value)
    
    private var subscriptions : [AnyCancellable?] = [nil,nil]
    private var valueDidSet : (() -> Void)?
    private var value : Value

    private func cancelSubscriptions() {
        subscriptions.enumerated().forEach({
            $0.element?.cancel()
            subscriptions[$0.offset] = nil
        })
    }

    deinit {
        cancelSubscriptions()
    }
}

extension PbPublished: Codable where Value: Codable
{
    public convenience init(from decoder: Decoder) throws {
        let value = try Value(from: decoder)
        self.init(wrappedValue: value)
        
        if let value = value as? PbObservableObjectType {
            valueDidSet = { [weak self] in
                self?.cancelSubscriptions()
                self?.subscriptions[0] = value.objectWillChange.sink { [weak self] _ in self?._objectWillChange?.send() }
                self?.subscriptions[1] = value.objectDidChange.sink { [weak self] _ in self?._objectDidChange?.send() }
            }
            valueDidSet!()
        }
    }

    public func encode(to encoder: Encoder) throws where Value: Codable {
        try value.encode(to: encoder)
    }
}
