/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Combine
import Foundation

/// A property that can report changes to the parent.
///
/// The properties `_objectWillChange` and `_objectDidChange`should be declared
/// but should never be initialized. Their initialization will take place automatically from
/// the parent object (if it's an object that conforms to PbObservableObject).
public protocol PbPublishedProperty {
    /// Publisher for `willSet` events, in the parent observable object.
    var _objectWillChange: ObservableObjectPublisher? { get nonmutating set }

    /// Publisher for `didSet` events, in the parent observable object.
    var _objectDidChange: ObservableObjectPublisher? { get nonmutating set }
}

@propertyWrapper
public final class PbPublished<Value>: PbPublishedProperty {
    public enum Options {
        case withLock
    }

    public var wrappedValue: Value {
        get {
            lock?.lock()
            let v = value
            lock?.unlock()
            return v
        }
        set {
            _objectWillChange?.send()
            valueWillChange.send(newValue)

            lock?.lock()
            value = newValue
            lock?.unlock()

            _objectDidChange?.send()

            valueDidSet?()
        }
    }

    public lazy var projectedValue = valueWillChange.eraseToAnyPublisher()

    public init(wrappedValue: Value, _ options: Options? = nil) {
        value = wrappedValue
        parseOptions(options)
    }

    public init(wrappedValue: Value, _ options: Options? = nil) where Value: PbObservableObject {
        value = wrappedValue
        parseOptions(options)
        valueDidSet = { [weak self] in
            self?.cancelSubscriptions()
            self?.subscriptions[0] = self?.value.objectWillChange.sink { [weak self] _ in self?._objectWillChange?.send() }
            self?.subscriptions[1] = self?.value.objectDidChange.sink { [weak self] _ in self?._objectDidChange?.send() }
        }
        valueDidSet!()
    }

    public var _objectWillChange: ObservableObjectPublisher?
    public var _objectDidChange: ObservableObjectPublisher?

    private lazy var valueWillChange = CurrentValueSubject<Value, Never>(value)

    private var subscriptions: [AnyCancellable?] = [nil, nil]
    private var valueDidSet: (() -> Void)?

    private var lock: NSRecursiveLock?
    private var value: Value

    private func parseOptions(_ options: Options?) {
        if options == .withLock {
            lock = NSRecursiveLock()
        }
    }

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

extension PbPublished: Encodable where Value: Encodable {
    public func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

extension PbPublished: Decodable where Value: Decodable {
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
}
