/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

extension PropertyListDecoder: PbDecoder {}
extension PropertyListEncoder: PbEncoder {}

public struct PropertyListCoder: PbCoder {
    private let decoder: PropertyListDecoder?
    private let encoder: PropertyListEncoder?

    public struct Box<T: Codable>: Codable {
        public let v: T
        public init(v: T) {
            self.v = v
        }
    }

    public init(decoder: PropertyListDecoder? = PropertyListDecoder(), encoder: PropertyListEncoder? = PropertyListEncoder()) {
        self.decoder = decoder
        self.encoder = encoder
    }

    public func decode<T>(_ type: T.Type, from: Data) throws -> T where T: Decodable {
        guard let decoder = decoder else { throw MachError(.invalidArgument) }
        do {
            if type.self == String.self {
                return try decoder.decode(Box<String>.self, from: from).v as! T
            }
            if type.self == Bool.self {
                return try decoder.decode(Box<Bool>.self, from: from).v as! T
            }
            if type.self == Int.self {
                return try decoder.decode(Box<Int>.self, from: from).v as! T
            }
            if type.self == Float.self {
                return try decoder.decode(Box<Float>.self, from: from).v as! T
            }
            if type.self == Double.self {
                return try decoder.decode(Box<Double>.self, from: from).v as! T
            }
            return try decoder.decode(type, from: from)
        } catch {
            dbg(Self.self, error)
            throw error
        }
    }

    public func encode<T>(_ value: T) throws -> Data where T: Encodable {
        guard let encoder = encoder else { throw MachError(.invalidArgument) }
        do {
            if let value = value as? String {
                return try encoder.encode(Box<String>(v: value))
            }
            if let value = value as? Bool {
                return try encoder.encode(Box<Bool>(v: value))
            }
            if let value = value as? Int {
                return try encoder.encode(Box<Int>(v: value))
            }
            if let value = value as? Float {
                return try encoder.encode(Box<Float>(v: value))
            }
            if let value = value as? Double {
                return try encoder.encode(Box<Double>(v: value))
            }
            return try encoder.encode(value)
        } catch {
            dbg(Self.self, error)
            throw error
        }
    }
}
