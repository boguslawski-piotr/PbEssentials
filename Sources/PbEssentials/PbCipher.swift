/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

public protocol PbDecipher
{
    /// Should decrypt and decode data into object of type T.
    func decrypt<T>(itemOf type: T.Type, from data: Data) throws -> T where T: Decodable

    /// Should decrypt binary data,
    func decrypt<T>(data: T) throws -> Data where T: DataProtocol
}

public protocol PbEncipher
{
    /// Should encode and encrypt item of type T into object of type Data.
    func encrypt<T>(_ item: T) throws -> Data where T: Encodable

    /// Should encrypt binary data.
    func encrypt<T>(data: T) throws -> Data where T: DataProtocol
}

public protocol PbCipher : PbDecipher, PbEncipher {}

open class PbCipherBase : PbCipher
{
    open lazy var coder = PropertyListCoder()

    open func encrypt<T>(_ item: T) throws -> Data where T: Encodable {
        try encrypt(data: try coder.encode(item))
    }

    open func decrypt<T>(itemOf type: T.Type, from data: Data) throws -> T where T: Decodable {
        try coder.decode(type, from: try decrypt(data: data))
    }
    
    open func encrypt<T>(data: T) throws -> Data where T: DataProtocol { fatalError("Abstract!") }
    open func decrypt<T>(data: T) throws -> Data where T: DataProtocol { fatalError("Abstract!") }
}

