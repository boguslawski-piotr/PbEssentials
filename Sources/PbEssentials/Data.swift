import Foundation
import AppleArchive

public extension Data
{
    typealias Compression = AppleArchive.ArchiveCompression

    func write(to url: URL, compression: Compression) throws {
        if compression == .none {
            return try write(to: url)
        }
        
        try PbCompressor(createFile: url.path, compression: compression)
            .append(data: self)
            .close()
    }
    
    init(contentsOf url: URL, decompress: Bool) throws {
        if !decompress {
            try self.init(contentsOf: url)
        }
        else {
            self = try PbDecompressor(openFile: url.path).read() ?? Data()
        }
    }
}
