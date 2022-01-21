/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation
import CryptoKit

// MARK: Protocols

/// A type that defines methods for decrypting.
public protocol PbDecipher
{
    /// Should decrypt data into object of type T.
    func decrypt<T>(itemOf type: T.Type, from data: Data) throws -> T where T : Decodable
}

/// A type that defines methods for encrypting.
public protocol PbEncipher
{
    /// Should encrypt item of type T into object of type Data.
    func encrypt<T>(_ item: T) throws -> Data where T : Encodable
}

public protocol PbCipher : PbDecipher, PbEncipher {}

// MARK: Basic implementations

public final class PbSimpleCipher : PbCipher
{
    public typealias SymmetricKey = CryptoKit.SymmetricKey

    private var key : SymmetricKey
    private lazy var coder = PropertyListCoder()
    
    public init(_ key: SymmetricKey) {
        self.key = key
    }
    
    public func encrypt<T>(_ item: T) throws -> Data where T : Encodable {
        let data = try coder.encode(item)
        return try ChaChaPoly.seal(data, using: key).combined
    }
    
    public func decrypt<T>(itemOf type: T.Type, from data: Data) throws -> T where T : Decodable {
        let sealedBox = try ChaChaPoly.SealedBox(combined: data)
        return try coder.decode(type, from: try ChaChaPoly.open(sealedBox, using: key))
    }
}
