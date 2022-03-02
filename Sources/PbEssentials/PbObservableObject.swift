/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Combine
import Foundation

/// A type of object with a publishers that emits before and after the object has changed.
public protocol PbObservableObject: ObservableObject, PbObservableObjectType, Identifiable {
    /// The type of publisher that emits after the object has changed.
    associatedtype ObjectDidChangePublisher: Publisher = ObservableObjectPublisher where ObjectDidChangePublisher.Failure == Never

    /// A publisher that emits after the object has changed.
    var objectDidChange: ObjectDidChangePublisher { get }
}

extension PbObservableObject where Self.ObjectWillChangePublisher == ObservableObjectPublisher, Self.ObjectDidChangePublisher == ObservableObjectPublisher
{
    public var objectWillChange: ObservableObjectPublisher { observableObjectPublisher(type: .will) }
    public var objectDidChange: ObservableObjectPublisher { observableObjectPublisher(type: .did) }
}

/// Protocol that you can use to recognize objects that conforms to PbObservableObject in runtime.
/// It doesn't have the associated type and can be used as a type :) in code like this:
///
///     if let obj = obj as? PbObservableObjectType {
///         objectWillChange.sink { ... }
///     }
public protocol PbObservableObjectType: AnyObject {
    var objectWillChange: ObservableObjectPublisher { get }
    var objectDidChange: ObservableObjectPublisher { get }
}

/// Base class for observable objects that may wish to retransmit changes from other observable objects.
open class PbObservableObjectBase: PbObservableObject {
    public lazy var _subscriptions: [AnyCancellable?] = []
    public lazy var _lock = NSRecursiveLock()
    
    open func subscribe<Value: PbObservableObject>(to value: Value) {
        _lock.lock()
        defer { _lock.unlock() }
        _subscriptions.append(value.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() })
        _subscriptions.append(value.objectDidChange.sink { [weak self] _ in self?.objectDidChange.send() })
    }
    
    open func cancelSubscriptions() {
        _lock.lock()
        defer { _lock.unlock() }
        _subscriptions.enumerated().forEach {
            $0.element?.cancel()
            _subscriptions[$0.offset] = nil
        }
        _subscriptions.removeAll()
    }
    
    deinit {
        cancelSubscriptions()
    }
}

// MARK: Private implementation

extension PbObservableObject where Self.ObjectWillChangePublisher == ObservableObjectPublisher, Self.ObjectDidChangePublisher == ObservableObjectPublisher
{
    fileprivate func observableObjectPublisher(type: Storage.PublisherType) -> ObservableObjectPublisher {
        // Simple concept:
        // If object has no properties marked with @PbPublished then return publisher from global cache
        // else:
        //   - first call: visit all properties marked with @PbPublished and install new, not stored in cache, publisher
        //   - next calls: return publisher from first property (properties cannot be deleted or created at runtime)
        var publisher: ObservableObjectPublisher?
        var reflection: Mirror? = Mirror(reflecting: self)
        while let aClass = reflection {
            for (_, property) in aClass.children {
                guard let publishedProperty = property as? PbPublishedProperty else { continue }
                if type == .will {
                    if publishedProperty._objectWillChange != nil { return publishedProperty._objectWillChange! }
                    publisher = (publisher == nil) ? ObservableObjectPublisher() : publisher
                    publishedProperty._objectWillChange = publisher
                } else {
                    if publishedProperty._objectDidChange != nil { return publishedProperty._objectDidChange! }
                    publisher = (publisher == nil) ? ObservableObjectPublisher() : publisher
                    publishedProperty._objectDidChange = publisher
                }
            }
            reflection = aClass.superclassMirror
        }
        return publisher ?? Storage.shared.publisher(of: type, for: id)
    }
}

private class Storage {
    @PbWithLock private var publishers: [ObjectIdentifier: [ObservableObjectPublisher?]] = [:]

    static var shared: Storage = Storage()

    enum PublisherType: Int {
        case will = 0
        case did = 1
    }

    func publisher(of type: PublisherType, for id: ObjectIdentifier) -> ObservableObjectPublisher {
        var publisher: ObservableObjectPublisher?
        $publishers.withLock {
            if publishers[id] != nil {
                publisher = publishers[id]?[type.rawValue]
            }
        }
        if publisher == nil {
            publisher = ObservableObjectPublisher()
            $publishers.withLock {
                if publishers[id] == nil {
                    publishers[id] = [nil, nil]
                }
                publishers[id]?[type.rawValue] = publisher
            }
        }
        return publisher!
    }
}
