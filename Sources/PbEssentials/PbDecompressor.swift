import Foundation
import System
import AppleArchive

public class PbDecompressor : Sequence, AsyncSequence, IteratorProtocol, ThrowingIteratorProtocol
{
    public init(openFile atPath: String, permissions: FilePermissions? = nil) throws {
        inputStream = ArchiveByteStream.fileStream(
            path: FilePath(atPath),
            mode: .readOnly,
            options: [.closeOnExec, .nonBlocking],
            permissions: permissions ?? FilePermissions(rawValue: 0o644))
        guard inputStream != nil else { throw ArchiveError.ioError }
        try makeDecompressAndDecodeStreams()
    }
    
    public func read() throws -> Data? {
        return try _next()
    }
    
    public func close() throws {
        try decodeStream?.close()
        try decompressStream?.close()
        try inputStream?.close()
        decodeStream = nil
        decompressStream = nil
        inputStream = nil
    }
    
    deinit {
        try? close()
    }
    
    // MARK: Sequences and Iterators conformance implementation
    
    public struct AsyncIterator : AsyncIteratorProtocol
    {
        let decompressor : PbDecompressor
        public func next() async throws -> Element? {
            return try decompressor._next()
        }
    }
    
    public __consuming func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(decompressor: self)
    }
    
    public typealias Element = Data
    
    public func nextThrows() throws -> Data? {
        return try _next()
    }
    
    public func next() -> Data? {
        return try? _next()
    }
    
    // MARK: Decompression implementation
    
    private var inputStream : ArchiveByteStream?
    private var decompressStream : ArchiveByteStream?
    private var decodeStream : ArchiveStream?
    
    private func makeDecompressAndDecodeStreams() throws {
        decompressStream = ArchiveByteStream.decompressionStream(readingFrom: inputStream!)
        guard decompressStream != nil else {
            try close()
            throw ArchiveError.ioError
        }
        
        decodeStream = ArchiveStream.decodeStream(readingFrom: decompressStream!)
        guard decodeStream != nil else {
            try close()
            throw ArchiveError.ioError
        }
    }
    
    private func _next() throws -> Data? {
        guard let header = try decodeStream?.readHeader() else {
            try close()
            return nil
        }
        
        let datField = header.field(forKey: .init("DAT"))
        let datSize : UInt64
        switch datField {
        case .blob(_, let size, _):
            datSize = size
        default:
            datSize = 0
        }
        
        var data : Data? = nil
        let rawBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: Int(datSize), alignment: MemoryLayout<UTF8>.alignment)
        defer {
            rawBuffer.deallocate()
        }
        try decodeStream!.readBlob(key: .init("DAT"), into: rawBuffer)
        rawBuffer.withUnsafeBytes { ptr in
            data = Data(ptr)
        }
        return data
    }
}
