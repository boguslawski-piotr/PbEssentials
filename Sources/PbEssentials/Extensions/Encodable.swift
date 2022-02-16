/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

extension Encodable {
    public func encoded(using encoder: PbEncoder = PropertyListCoder(decoder: nil)) throws -> Data {
        try encoder.encode(self)
    }
    
    public func compressed(using compressor: PbCompressor, encoder: PbEncoder = PropertyListCoder(decoder: nil)) throws -> Data {
        try compressor.compress(data: self.encoded(using: encoder))
    }

    public func encrypted(using encipher: PbEncipher, encoder: PbEncoder = PropertyListCoder(decoder: nil)) throws -> Data {
        try encipher.encrypt(data: self.encoded(using: encoder))
    }
}
