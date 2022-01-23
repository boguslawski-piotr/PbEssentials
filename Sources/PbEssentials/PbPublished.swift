/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Combine

public protocol PbPublishedProperty
{
    var parentObjectWillChange : ObservableObjectPublisher? { get set }
    var parentObjectDidChange : ObservableObjectPublisher? { get set }
}

@propertyWrapper
public final class PbPublished<Value> : PbPublishedProperty
{
    public var wrappedValue : Value {
        get { value }
        set {
            parentObjectWillChange?.send()
            valueWillChange.send(newValue)
            
            value = newValue
            
            valueDidChange.send(newValue)
            parentObjectDidChange?.send()

            valueDidSet?()
        }
    }

    public struct PublicValuePublishers
    {
        public var willChange : AnyPublisher<Value, Never>
        public var didChange : AnyPublisher<Value, Never>
    }

    public lazy var projectedValue = PublicValuePublishers(willChange: valueWillChange.eraseToAnyPublisher(),
                                                           didChange: valueDidChange.eraseToAnyPublisher())
    
    public init(wrappedValue: Value) {
        value = wrappedValue
    }

    public init(wrappedValue: Value) where Value: PbObservableObject {
        value = wrappedValue
        valueDidSet = { [weak self] in
            self?.cancelSubscriptions()
            self?.subscriptions[0] = self?.value.objectWillChange.sink { [weak self] _ in self?.parentObjectWillChange?.send() }
            self?.subscriptions[1] = self?.value.objectDidChange.sink { [weak self] _ in self?.parentObjectDidChange?.send() }
        }
        valueDidSet!()
    }

    public var parentObjectWillChange : ObservableObjectPublisher?
    public var parentObjectDidChange : ObservableObjectPublisher?

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
        // TODO: Find a way to identify value as a PbObservableObject
    }

    public func encode(to encoder: Encoder) throws where Value: Codable {
        try value.encode(to: encoder)
    }
}
