import Foundation
import System
import AppleArchive

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
open class PbDecompressor : Sequence, AsyncSequence, IteratorProtocol, ThrowingIteratorProtocol
{
    public init(fromFile atPath: String, permissions: FilePermissions? = nil) throws {
        inputStream = ArchiveByteStream.fileStream(
            path: FilePath(atPath),
            mode: .readOnly,
            options: [.closeOnExec, .nonBlocking],
            permissions: permissions ?? FilePermissions(rawValue: 0o644))
        try makeDecompressAndDecodeStreams()
    }
    
    public init<Stream>(fromStream stream : Stream) throws where Stream: AnyObject, Stream: ArchiveByteStreamProtocol {
        inputStream = ArchiveByteStream.customStream(instance: stream)
        try makeDecompressAndDecodeStreams()
    }
    
    public func read() throws -> Data? {
        return try _next()
    }

    public func read(_ name: inout String) throws -> Data? {
        let data = try _next()
        name = lastName
        return data
    }

    public func close() throws {
        try decodeStream?.close()
        try decompressStream?.close()
        try inputStream?.close()
        decodeStream = nil
        decompressStream = nil
        inputStream = nil
        lastError = nil
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
    
    public var lastError : Error?

    public func next() -> Data? {
        do {
            return try _next()
        }
        catch {
            lastError = error
            return nil
        }
    }
    
    // MARK: Decompression implementation
    
    private var inputStream : ArchiveByteStream?
    private var decompressStream : ArchiveByteStream?
    private var decodeStream : ArchiveStream?
    
    private func makeDecompressAndDecodeStreams() throws {
        guard inputStream != nil else {
            throw ArchiveError.ioError
        }

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
    
    private var lastName = ""
    
    private func _next() throws -> Data? {
        guard let header = try decodeStream?.readHeader() else {
            try close()
            return nil
        }
        
        let patField = header.field(forKey: .init("PAT"))
        lastName = ""
        if case .string(_, let name) = patField {
            lastName = name
        }

        let datField = header.field(forKey: .init("DAT"))
        var datSize : UInt64 = 0
        if case .blob(_, let size, _) = datField {
            datSize = size
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
