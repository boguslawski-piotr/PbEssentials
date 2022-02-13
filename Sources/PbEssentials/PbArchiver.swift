/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

public enum PbCompression {
    case fast, strong
}

public protocol PbCompressor {
    /// Should encode and compress item of type T into object of type Data.
    func compress<T>(_ item: T) throws -> Data where T: Encodable

    /// Should compress binary data.
    func compress(data: Data) throws -> Data
}

public protocol PbDecompressor {
    /// Should decompress and decode data into object of type T.
    func decompress<T>(itemOf type: T.Type, from data: Data) throws -> T where T: Decodable

    /// Should decompress binary data,
    func decompress(data: Data) throws -> Data
}

public protocol PbArchiver: PbCompressor, PbDecompressor {}

open class PbArchiverBase: PbArchiver {
    open lazy var coder = PropertyListCoder()

    open func compress<T>(_ item: T) throws -> Data where T: Encodable {
        try compress(data: try coder.encode(item))
    }

    open func decompress<T>(itemOf type: T.Type, from data: Data) throws -> T where T: Decodable {
        try coder.decode(type, from: try decompress(data: data))
    }

    open func compress(data: Data) throws -> Data { fatalError("Abstract!") }
    open func decompress(data: Data) throws -> Data { fatalError("Abstract!") }
}
