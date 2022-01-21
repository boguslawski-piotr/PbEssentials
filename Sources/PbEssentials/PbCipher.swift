/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation
import Combine

// MARK: Protocols

/// A type that defines methods for decrypting.
public protocol PbDecipher
{
    /// Should decrypt data into object of type T.
    func decrypt<T>(itemOf type: T.Type, from data: Data) throws -> T? where T : Decodable
}

/// A type that defines methods for encrypting.
public protocol PbEncipher
{
    /// Should encrypt item of type T into object of type Data.
    func encrypt<T>(_ item: T) throws -> Data where T : Encodable
}

public protocol PbCipher : PbDecipher, PbEncipher {}

// MARK: Basic implementations

// TODO: simple Cipher using Apple CryptoKit


