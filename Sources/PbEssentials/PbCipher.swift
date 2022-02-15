/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

public protocol PbEncipher {
    /// Should encrypt binary data.
    func encrypt<T>(data: T) throws -> Data where T: DataProtocol
}

public extension PbEncipher {
    /// Encode and encrypt item of type T into object of type Data.
    func encrypt<T>(_ item: T, encoder: PbEncoder) throws -> Data where T: Encodable {
        try encrypt(data: try encoder.encode(item))
    }
}

public protocol PbDecipher {
    /// Should decrypt binary data.
    func decrypt<T>(data: T) throws -> Data where T: DataProtocol
}

public extension PbDecipher {
    /// Decrypt and decode data into object of type T.
    func decrypt<T>(itemOf type: T.Type, from data: Data, decoder: PbDecoder) throws -> T where T: Decodable {
        try decoder.decode(type, from: try decrypt(data: data))
    }
}

public protocol PbCipher: PbDecipher & PbEncipher {}
