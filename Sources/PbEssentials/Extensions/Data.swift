/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation
import AppleArchive

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public extension Data
{
    #if !targetEnvironment(simulator)

    typealias Compression = AppleArchive.ArchiveCompression

    func write(to url: URL, compression: Compression) throws {
        if compression == .none {
            return try write(to: url)
        }
        
        try PbAppleArchiveCompressor(toFile: url.path, compression: compression)
            .append(data: self)
            .close()
    }

    init(contentsOf url: URL, decompress: Bool) throws {
        if !decompress {
            try self.init(contentsOf: url)
        }
        else {
            self = try PbAppleArchiveDecompressor(fromFile: url.path).read() ?? Data()
        }
    }
    
    #endif
    
    func write(to url: URL, compressor: PbCompressorProtocol?) throws {
        if compressor == nil {
            return try write(to: url)
        }
        
        try compressor?.create(file: url.path, permissions: nil)
            .append(data: self, withName: nil)
            .close()
    }

    init(contentsOf url: URL, decompressor: PbDecompressorProtocol?) throws {
        if decompressor == nil {
            try self.init(contentsOf: url)
        }
        else {
            self = try decompressor?.open(file: url.path, permissions: nil).read() ?? Data()
        }
    }
}
