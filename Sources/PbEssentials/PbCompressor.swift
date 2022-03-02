/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

public protocol PbCompressor {
    /// Should compress binary data.
    func compress(data: Data) throws -> Data
}

public extension PbCompressor {
    /// Encode and compress item of type T into object of type Data.
    func compress<T>(_ item: T, encoder: PbEncoder) throws -> Data where T: Encodable {
        try compress(data: try encoder.encode(item))
    }
}

public protocol PbDecompressor {
    /// Should decompress binary data.
    func decompress(data: Data) throws -> Data
}

public extension PbDecompressor {
    /// Decompress and decode data into item of type T.
    func decompress<T>(itemOf type: T.Type, from data: Data, decoder: PbDecoder) throws -> T where T: Decodable {
        try decoder.decode(type, from: try decompress(data: data))
    }
}
