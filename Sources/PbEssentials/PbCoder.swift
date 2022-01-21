/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

// MARK: PbDecoder

public protocol PbDecoder
{
    func decode<T>(_ type: T.Type, from: Data) throws -> T where T : Decodable
}

public extension Data
{
    func decoded<T: Decodable>(as type: T.Type = T.self, using decoder: PbDecoder = JSONCoder(withoutEncoder: true)) throws -> T {
        try decoder.decode(T.self, from: self)
    }
}

extension JSONDecoder: PbDecoder {}
extension PropertyListDecoder: PbDecoder {}

// MARK: PbEncoder

public protocol PbEncoder
{
    func encode<T>(_ value: T) throws -> Data where T : Encodable
}

public extension Encodable
{
    func encoded(using encoder: PbEncoder = JSONCoder(withoutDecoder: true)) throws -> Data {
        try encoder.encode(self)
    }
}

extension JSONEncoder: PbEncoder {}
extension PropertyListEncoder: PbEncoder {}

// MARK: PbCoder

public protocol PbCoder : PbDecoder, PbEncoder
{
    var decoder : PbDecoder? { get }
    var encoder : PbEncoder? { get }
}

open class PbCoderBase<D, E> : PbCoder where D: PbDecoder, E: PbEncoder
{
    public var decoder: PbDecoder?
    public var encoder: PbEncoder?

    public init(_ d: D?, _ e: E?) {
        decoder = d
        encoder = e
    }

    open func decode<T>(_ type: T.Type, from: Data) throws -> T where T : Decodable {
        guard let decoder = decoder else { throw CocoaError(.coderInvalidValue) }
        return try decoder.decode(type, from: from)
    }

    open func encode<T>(_ value: T) throws -> Data where T : Encodable {
        guard let encoder = encoder else { throw CocoaError(.coderInvalidValue) }
        return try encoder.encode(value)
    }
}

// MARK: JSONCoder

open class JSONCoder : PbCoderBase<JSONDecoder, JSONEncoder>
{
    public init(withoutDecoder: Bool = false, withoutEncoder: Bool = false) {
        super.init(withoutDecoder ? nil : JSONDecoder(), withoutEncoder ? nil : JSONEncoder())
    }
}

// MARK: PropertyListCoder

open class PropertyListCoder : PbCoderBase<PropertyListDecoder, PropertyListEncoder>
{
    public struct Box<T : Codable> : Codable
    {
        public let v : T
        public init(v: T) {
            self.v = v
        }
    }
    
    public init(withoutDecoder: Bool = false, withoutEncoder: Bool = false) {
        super.init(withoutDecoder ? nil : PropertyListDecoder(), withoutEncoder ? nil : PropertyListEncoder())
    }

    open override func decode<T>(_ type: T.Type, from: Data) throws -> T where T : Decodable {
        guard let decoder = decoder else { throw CocoaError(.coderInvalidValue) }
        do {
            if type.self == String.self {
                return try decoder.decode(Box<String>.self, from: from).v as! T
            }
            // TODO: Int, Bool, etc.
            return try decoder.decode(type, from: from)
        }
        catch {
            dbg(Self.self, error)
            throw error
        }
    }
    
    open override func encode<T>(_ value: T) throws -> Data where T : Encodable {
        guard let encoder = encoder else { throw CocoaError(.coderInvalidValue) }
        do {
            if let value = value as? String {
                return try encoder.encode(Box<String>(v: value))
            }
            // TODO: Int, Bool, etc.
            return try encoder.encode(value)
        }
        catch {
            dbg(Self.self, error)
            throw error
        }
    }
}

