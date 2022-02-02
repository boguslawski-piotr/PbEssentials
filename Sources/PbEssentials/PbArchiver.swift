/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation
import System

public enum PbCompression
{
    case fast, strong
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public protocol PbCompressor
{
    init(compression: PbCompression)
    mutating func create(file atPath: String, permissions: FilePermissions?) throws
    mutating func append(contentsOf url: URL, withName: String?) throws
    mutating func append(data: Data, withName: String?) throws
    mutating func close() throws
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public protocol PbDecompressor
{
    init()
    mutating func open(file atPath: String, permissions: FilePermissions?) throws
    mutating func read() throws -> Data?
    mutating func readWithName() throws -> (Data?, String)
    mutating func close() throws
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public protocol PbArchiver
{
    func makeCompressor() -> PbCompressor
    func makeDecompressor() -> PbDecompressor
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
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
