/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

extension JSONDecoder: PbDecoder {}
extension JSONEncoder: PbEncoder {}

public struct JSONCoder: PbCoder {
    private let decoder: JSONDecoder?
    private let encoder: JSONEncoder?

    public init(decoder: JSONDecoder? = JSONDecoder(), encoder: JSONEncoder? = JSONEncoder()) {
        self.decoder = decoder
        self.encoder = encoder
    }

    public func decode<T>(_ type: T.Type, from: Data) throws -> T where T: Decodable {
        guard let decoder = decoder else { throw MachError(.invalidArgument) }
        return try decoder.decode(type, from: from)
    }

    public func encode<T>(_ value: T) throws -> Data where T: Encodable {
        guard let encoder = encoder else { throw MachError(.invalidArgument) }
        return try encoder.encode(value)
    }
}
