//
//  Created by Piotr Boguslawski on 10/01/2022.
//

import Foundation
import Combine

// MARK: JSON/PropertyList Encoder/Decoder Extensions

public extension TopLevelDecoder
{
    static func decode<T, D>(_ d : D, _ type: T.Type, from: Data) throws -> T where T : Decodable, D : TopLevelDecoder, D.Input == Data {
        do {
            if type.self == String.self {
                return try d.decode(Box<String>.self, from: from).v as! T
            }
            return try d.decode(type, from: from)
        }
        catch {
            print(error)
            throw error
        }
    }
}

public extension TopLevelEncoder
{
    static func encode<T, E>(_ e : E, _ value : T) throws -> Data where T : Encodable, E : TopLevelEncoder, E.Output == Data {
        do {
            if let value = value as? String {
                return try e.encode(Box<String>(v: value))
            }
            return try e.encode(value)
        }
        catch {
            print(error)
            throw error
        }
    }
    
}

public protocol TopLevelCoder
{
    func decode<T>(_ type: T.Type, from: Data) throws -> T where T : Decodable
    func encode<T>(_ value: T) throws -> Data where T : Encodable
}

open class TopLevelCoderBase<D, E> : TopLevelCoder where D : TopLevelDecoder, D.Input == Data, E : TopLevelEncoder, E.Output == Data
{
    open var decoder : D?
    open var encoder : E?
    
    @inlinable
    open func decode<T>(_ type: T.Type, from: Data) throws -> T where T : Decodable {
        try D.decode(decoder!, type, from: from)
    }
    
    @inlinable
    open func encode<T>(_ value: T) throws -> Data where T : Encodable {
        try E.encode(encoder!, value)
    }
    
    public init(_ d : D, _ e : E) {
        decoder = d
        encoder = e
    }
}

open class JSONCoder : TopLevelCoderBase<JSONDecoder, JSONEncoder>
{
    public init() {
        super.init(JSONDecoder(), JSONEncoder())
    }
}

open class PropertyListCoder : TopLevelCoderBase<PropertyListDecoder, PropertyListEncoder>
{
    public init() {
        super.init(PropertyListDecoder(), PropertyListEncoder())
    }
}

// MARK: Private implementation

fileprivate struct Box<T : Codable> : Codable
{
    let v : T
}
