/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation
import System

public enum PbCompression
{
    case fast, strong
}

public protocol PbCompressor
{
    init(compression: PbCompression)
    mutating func create(file atPath: String) throws
    mutating func append(contentsOf url: URL, withName: String?) throws
    mutating func append(data: Data, withName: String?) throws
    mutating func close() throws
}

public protocol PbDecompressor
{
    init()
    mutating func open(file atPath: String) throws
    mutating func read() throws -> Data?
    mutating func readWithName() throws -> (Data?, String)
    mutating func close() throws
}

public protocol PbArchiver
{
    func makeCompressor() -> PbCompressor
    func makeDecompressor() -> PbDecompressor
}

public struct PbSimpleArchiver<Compressor: PbCompressor, Decompressor: PbDecompressor> : PbArchiver
{
    let compression : PbCompression
    
    public init(compression: PbCompression) {
        self.compression = compression
    }
    
    public func makeCompressor() -> PbCompressor {
        Compressor.init(compression: compression)
    }
    
    public func makeDecompressor() -> PbDecompressor {
        Decompressor.init()
    }
}
