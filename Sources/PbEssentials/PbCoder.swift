/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

public protocol PbDecoder {
    func decode<T>(_ type: T.Type, from: Data) throws -> T where T: Decodable
}

public protocol PbEncoder {
    func encode<T>(_ value: T) throws -> Data where T: Encodable
}

public protocol PbCoder: PbDecoder, PbEncoder {}
