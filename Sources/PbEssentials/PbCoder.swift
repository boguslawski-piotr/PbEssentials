/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

public protocol PbDecoder {
    /// Should decode biinary data into object of type T.
    func decode<T>(_ type: T.Type, from: Data) throws -> T where T: Decodable
}

public protocol PbEncoder {
    /// Should encode object of type T into binary data.
    func encode<T>(_ value: T) throws -> Data where T: Encodable
}

public protocol PbCoder: PbDecoder, PbEncoder {}
