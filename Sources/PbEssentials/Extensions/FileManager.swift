/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation
import System
import AppleArchive

#if !targetEnvironment(simulator)

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public extension FileManager
{
    typealias Compression = AppleArchive.ArchiveCompression
    
    fileprivate func attributesToFilePermissions(_ attr: [FileAttributeKey : Any]?) -> FilePermissions {
        FilePermissions(rawValue: (attr?[.posixPermissions] as? NSNumber)?.uint16Value ?? 0o644)
    }
    
    func createFile(atPath path: String, contents data: Data?, compression: Compression, attributes attr: [FileAttributeKey : Any]? = nil) -> Bool {
        if compression == .none {
            return createFile(atPath: path, contents: data, attributes: attr)
        }
        
        do {
            var cf = try PbAppleArchiveCompressor(toFile: path, compression: compression, permissions: attributesToFilePermissions(attr))
            try cf.append(data: data ?? Data())
            try cf.close()
            return true
        }
        catch {
            return false
        }
    }
    
    func contents(atPath path: String, decompress: Bool) -> Data? {
        if !decompress {
            return contents(atPath: path)
        }
        
        do {
            var df = try PbAppleArchiveDecompressor(fromFile: path)
            let result = try df.read()
            try df.close()
            return result
        }
        catch {
            return nil
        }
    }
}

#endif
