/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

extension Data {
    public func write(to url: URL, compressor: PbCompressor, options: Data.WritingOptions = []) throws {
        let cdata = try compressor.compress(data: self)
        try cdata.write(to: url, options: options)
    }

    public init(contentsOf url: URL, decompressor: PbDecompressor, options: Data.ReadingOptions = []) throws {
        try self.init(contentsOf: url, options: options)
        self = try decompressor.decompress(data: self)
    }
}

extension Data {
    public func decoded<T: Decodable>(as type: T.Type = T.self, using decoder: PbDecoder = JSONCoder(encoder: nil)) throws -> T {
        try decoder.decode(T.self, from: self)
    }
}
