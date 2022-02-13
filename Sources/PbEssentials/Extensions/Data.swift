/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

public extension Data
{
    func write(to url: URL, compressor: PbCompressor, options: Data.WritingOptions = []) throws {
        let cdata = try compressor.compress(data: self)
        try cdata.write(to: url, options: options)
    }

    init(contentsOf url: URL, decompressor: PbDecompressor, options: Data.ReadingOptions = []) throws {
        try self.init(contentsOf: url, options: options)
        self = try decompressor.decompress(data: self)
    }
}

public extension Data
{
    func decoded<T: Decodable>(as type: T.Type = T.self, using decoder: PbDecoder = JSONCoder(encoder: nil)) throws -> T {
        try decoder.decode(T.self, from: self)
    }
}
