/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Combine

public protocol PbObservableObject : ObservableObject, Identifiable
{
    /// The type of publisher that emits after the object has changed.
    associatedtype ObjectDidChangePublisher : Publisher = ObservableObjectPublisher where ObjectDidChangePublisher.Failure == Never
    
    /// A publisher that emits after the object has changed.
    var objectDidChange : ObjectDidChangePublisher { get }
}

public extension PbObservableObject where Self.ObjectWillChangePublisher == ObservableObjectPublisher,
                                          Self.ObjectDidChangePublisher == ObservableObjectPublisher
{
    var objectWillChange : ObservableObjectPublisher { observableObjectPublisher(type: .will) }
    var objectDidChange : ObservableObjectPublisher { observableObjectPublisher(type: .did) }
}

public class PbObservableObjectBase : PbObservableObject {}

// MARK: Private implementation

fileprivate extension PbObservableObject where Self.ObjectWillChangePublisher == ObservableObjectPublisher,
                                               Self.ObjectDidChangePublisher == ObservableObjectPublisher
{
    func observableObjectPublisher(type : Storage.PublisherType) -> ObservableObjectPublisher {
        // Simple concept:
        // If object has no properties marked with @PbPublished then return publisher from global cache
        // else:
        //   - first call: visit all properties marked with @PbPublished and install new, not stored in cache, publisher
        //   - next calls: return publisher from first property (properties cannot be deleted or created at runtime)
        var publisher : ObservableObjectPublisher?
        var reflection : Mirror? = Mirror(reflecting: self)
        while let aClass = reflection {
            for (_, property) in aClass.children {
                guard var publishedProperty = property as? PbPublishedProperty else { continue }
                if type == .will {
                    if publishedProperty.parentObjectWillChange != nil { return publishedProperty.parentObjectWillChange! }
                    publisher = (publisher == nil) ? ObservableObjectPublisher() : publisher
                    publishedProperty.parentObjectWillChange = publisher
                }
                else {
                    if publishedProperty.parentObjectDidChange != nil { return publishedProperty.parentObjectDidChange! }
                    publisher = (publisher == nil) ? ObservableObjectPublisher() : publisher
                    publishedProperty.parentObjectDidChange = publisher
                }
            }
            reflection = aClass.superclassMirror
        }
        return publisher ?? Storage.shared.publisher(of: type, for: id)
    }
}

fileprivate class Storage
{
    @PbWithLock private var publishers : [ObjectIdentifier : [ObservableObjectPublisher?]] = [:]
    
    static var shared : Storage = Storage()
    
    enum PublisherType : Int {
        case will = 0, did = 1
    }
    
    func publisher(of type : PublisherType, for id : ObjectIdentifier) -> ObservableObjectPublisher {
        var publisher : ObservableObjectPublisher?
        $publishers.withLock {
            if publishers[id] != nil {
                publisher = publishers[id]?[type.rawValue]
            }
        }
        if publisher == nil {
            publisher = ObservableObjectPublisher()
            $publishers.withLock {
                if publishers[id] == nil {
                    publishers[id] = [nil,nil]
                }
                publishers[id]?[type.rawValue] = publisher
            }
        }
        return publisher!
    }
}
