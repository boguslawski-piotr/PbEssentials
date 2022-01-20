import Foundation
import System
import AppleArchive

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
open class PbCompressor
{
    public init(toFile atPath: String, compression: ArchiveCompression? = nil, permissions: FilePermissions? = nil) throws {
        try makeOutputFileStream(atPath, permissions ?? FilePermissions(rawValue: 0o644))
        try makeCompressAndEncodeStreams(compression)
    }

    public init<Stream>(toStream stream : Stream, compression: ArchiveCompression? = nil) throws where Stream: AnyObject, Stream: ArchiveByteStreamProtocol {
        outputStream = ArchiveByteStream.customStream(instance: stream)
        try makeCompressAndEncodeStreams(compression)
    }

    @discardableResult
    public func append(contentsOf url: URL, withName: String? = nil) throws -> PbCompressor {
        let data = try Data(contentsOf: url)
        return try append(data: data, withName: withName ?? url.lastPathComponent)
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

        try encodeStream!.writeHeader(header)
        
        try data.withUnsafeBytes() { ptr in
            let rawBuffer = UnsafeRawBufferPointer(ptr)
            try encodeStream!.writeBlob(key: .init("DAT"), from: rawBuffer)
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
    
    private var encodeStream : ArchiveStream?
    private var compressStream : ArchiveByteStream?
    private var outputStream : ArchiveByteStream?

    private func makeOutputFileStream(_ atPath: String, _ permissions: FilePermissions) throws {
        outputStream = ArchiveByteStream.fileStream(
            path: FilePath(atPath),
            mode: .writeOnly,
            options: [.truncate, .create, .closeOnExec],
            permissions: permissions)
    }
    
    private func makeCompressAndEncodeStreams(_ compression: ArchiveCompression?) throws {
        guard outputStream != nil else { throw ArchiveError.invalidValue }
        let compression = compression ?? .lzma
        
        compressStream = ArchiveByteStream.compressionStream(using: compression, writingTo: outputStream!)
        guard compressStream != nil else { throw ArchiveError.invalidValue }
        
        encodeStream = ArchiveStream.encodeStream(writingTo: compressStream!)
        guard encodeStream != nil else { throw ArchiveError.invalidValue }
    }
}

