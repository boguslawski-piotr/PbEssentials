/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

extension Encodable {
    public func encode(using encoder: PbEncoder = PropertyListCoder(decoder: nil)) throws -> Data {
        try encoder.encode(self)
    }
    
    public func compress(using compressor: PbCompressor, encoder: PbEncoder = PropertyListCoder(decoder: nil)) throws -> Data {
        try compressor.compress(data: self.encode(using: encoder))
    }

    public func encrypt(using encipher: PbEncipher, encoder: PbEncoder = PropertyListCoder(decoder: nil)) throws -> Data {
        try encipher.encrypt(data: self.encode(using: encoder))
    }
}
