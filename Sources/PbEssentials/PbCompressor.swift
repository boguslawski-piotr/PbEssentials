import Foundation
import System
import AppleArchive

public class PbCompressor
{
    public init(createFile atPath: String, compression: ArchiveCompression = .lzma, permissions: FilePermissions? = nil) throws {
        outputStream = ArchiveByteStream.fileStream(
            path: FilePath(atPath),
            mode: .writeOnly,
            options: [.truncate, .create, .closeOnExec],
            permissions: permissions ?? FilePermissions(rawValue: 0o644))
        guard outputStream != nil else { throw ArchiveError.ioError }
        try makeCompressAndEncodeStreams(compression)
    }

    @discardableResult
    public func append(data: Data, withName: String? = nil) throws -> PbCompressor {
        guard encodeStream != nil else { throw ArchiveError.invalidValue }
        
        let header = ArchiveHeader()
        if withName != nil {
            header.append(.string(key: .init("PAT"), value: withName!))
        }
        header.append(.uint(  key: .init("TYP"), value: UInt64(ArchiveHeader.EntryType.regularFile.rawValue)))
        header.append(.blob(  key: .init("DAT"), size:  UInt64(data.count)))

        try encodeStream?.writeHeader(header)
        
        try data.withUnsafeBytes() { ptr in
            let rawBuffer = UnsafeRawBufferPointer(ptr)
            try encodeStream?.writeBlob(key: .init("DAT"), from: rawBuffer)
        }
        
        return self
    }
    
    public func close() throws {
        try encodeStream?.close()
        try compressStream?.close()
        try outputStream?.close()
        encodeStream = nil
        compressStream = nil
        outputStream = nil
    }
    
    deinit {
        try? close()
    }
    
    private var outputStream : ArchiveByteStream?
    private var compressStream : ArchiveByteStream?
    private var encodeStream : ArchiveStream?
    
    private func makeCompressAndEncodeStreams(_ compression: ArchiveCompression) throws {
        compressStream = ArchiveByteStream.compressionStream(using: compression, writingTo: outputStream!)
        guard compressStream != nil else { throw ArchiveError.ioError }
        
        encodeStream = ArchiveStream.encodeStream(writingTo: compressStream!)
        guard encodeStream != nil else { throw ArchiveError.ioError }
    }
}

