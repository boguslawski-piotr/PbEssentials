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
    public func compressed(using compressor: PbCompressor) throws -> Data {
        try compressor.compress(data: self)
    }
    
    public func decompressed(using decompressor: PbDecompressor) throws -> Data {
        try decompressor.decompress(data: self)
    }
}

extension Data {
    public func encrypted(using encipher: PbEncipher) throws -> Data {
        try encipher.encrypt(data: self)
    }
    
    public func decrypted(using decipher: PbDecipher) throws -> Data {
        try decipher.decrypt(data: self)
    }
}

extension Data {
    public func decoded<T: Decodable>(as type: T.Type = T.self, using decoder: PbDecoder = PropertyListCoder(encoder: nil)) throws -> T {
        try decoder.decode(T.self, from: self)
    }

    public func decompressed<T: Decodable>(as type: T.Type = T.self, using decompressor: PbDecompressor, decoder: PbDecoder = PropertyListCoder(encoder: nil)) throws -> T {
        try decoder.decode(type, from: decompressor.decompress(data: self))
    }
    
    public func decrypted<T: Decodable>(as type: T.Type = T.self, using decipher: PbDecipher, decoder: PbDecoder = PropertyListCoder(encoder: nil)) throws -> T {
        try decoder.decode(type, from: decipher.decrypt(data: self))
    }
}
