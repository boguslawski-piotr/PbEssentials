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
        
        var cf = try PbAppleArchiveCompressor(toFile: url.path, compression: compression)
        try cf.append(data: self)
        try cf.close()
    }

    init(contentsOf url: URL, decompress: Bool) throws {
        if !decompress {
            try self.init(contentsOf: url)
        }
        else {
            var df = try PbAppleArchiveDecompressor(fromFile: url.path)
            self = try df.read() ?? Data()
            try df.close()
        }
    }
    
#endif
    
    func write(to url: URL, compressor: PbCompressor?) throws {
        if compressor == nil {
            return try write(to: url)
        }
        
        var cf = compressor!
        try cf.create(file: url.path, permissions: nil)
        try cf.append(data: self, withName: nil)
        try cf.close()
    }

    init(contentsOf url: URL, decompressor: PbDecompressor?) throws {
        if decompressor == nil {
            try self.init(contentsOf: url)
        }
        else {
            var df = decompressor!
            try df.open(file: url.path, permissions: nil)
            self = try df.read() ?? Data()
            try df.close()
        }
    }
}
