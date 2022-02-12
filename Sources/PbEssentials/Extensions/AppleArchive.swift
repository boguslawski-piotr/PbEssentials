/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation
import System
import AppleArchive

#if !targetEnvironment(simulator)

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public struct PbAppleArchiveCompressor : PbCompressor
{
    public init(compression: PbCompression) {
        switch compression {
        case .fast:
            self.compression = .lz4
        case .strong:
            self.compression = .lzma
        }
    }
    
    public init(compression: ArchiveCompression? = nil) {
        self.compression = compression
    }
    
    public init(toFile atPath: String, compression: ArchiveCompression? = nil, permissions: FilePermissions? = nil) throws {
        self.compression = compression
        try create(file: atPath, permissions: permissions)
    }
    
    public init<Stream>(toStream stream: Stream, compression: ArchiveCompression? = nil) throws where Stream: AnyObject, Stream: ArchiveByteStreamProtocol {
        self.compression = compression
        outputStream = ArchiveByteStream.customStream(instance: stream)
        try makeCompressAndEncodeStreams()
    }
    
    public mutating func create(file atPath: String) throws {
        try create(file: atPath, permissions: nil)
    }
    
    public mutating func create(file atPath: String, permissions: FilePermissions?) throws {
        try makeOutputFileStream(atPath, permissions ?? FilePermissions(rawValue: 0o644))
        try makeCompressAndEncodeStreams()
    }
    
    public mutating func append(contentsOf url: URL, withName: String? = nil) throws {
        let data = try Data(contentsOf: url)
        try append(data: data, withName: withName ?? url.lastPathComponent)
    }
    
    public mutating func append(data: Data, withName: String? = nil) throws {
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
    }
    
    public mutating func close() throws {
        try encodeStream?.close()
        try compressStream?.close()
        try outputStream?.close()
        encodeStream = nil
        compressStream = nil
        outputStream = nil
    }
    
    private var compression : ArchiveCompression?
    private var encodeStream : ArchiveStream?
    private var compressStream : ArchiveByteStream?
    private var outputStream : ArchiveByteStream?
    
    private mutating func makeOutputFileStream(_ atPath: String, _ permissions: FilePermissions) throws {
        outputStream = ArchiveByteStream.fileStream(
            path: FilePath(atPath),
            mode: .writeOnly,
            options: [.truncate, .create, .closeOnExec],
            permissions: permissions)
    }
    
    private mutating func makeCompressAndEncodeStreams() throws {
        guard outputStream != nil else { throw ArchiveError.invalidValue }
        let compression = self.compression ?? .lzma
        
        compressStream = ArchiveByteStream.compressionStream(using: compression, writingTo: outputStream!)
        guard compressStream != nil else { throw ArchiveError.invalidValue }
        
        encodeStream = ArchiveStream.encodeStream(writingTo: compressStream!)
        guard encodeStream != nil else { throw ArchiveError.invalidValue }
    }
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public struct PbAppleArchiveDecompressor : PbDecompressor, ErrorReportingSequence, AsyncSequence, ErrorReportingIteratorProtocol, ThrowingIteratorProtocol
{
    public init() {}
    
    public init(fromFile atPath: String, permissions: FilePermissions? = nil) throws {
        try open(file: atPath, permissions: permissions)
    }
    
    public init<Stream>(fromStream stream : Stream) throws where Stream: AnyObject, Stream: ArchiveByteStreamProtocol {
        inputStream = ArchiveByteStream.customStream(instance: stream)
        try makeDecompressAndDecodeStreams()
    }
    
    public mutating func open(file atPath: String) throws {
        try open(file: atPath, permissions: nil)
    }
    
    public mutating func open(file atPath: String, permissions: FilePermissions?) throws {
        try makeInputFileStream(atPath, permissions ?? FilePermissions(rawValue: 0o644))
        try makeDecompressAndDecodeStreams()
    }
    
    public mutating func read() throws -> Data? {
        return try _next()
    }

    public mutating func readWithName() throws -> (Data?, String) {
        let data = try _next()
        return (data, lastStringPatField)
    }

    public mutating func close() throws {
        try decodeStream?.close()
        try decompressStream?.close()
        try inputStream?.close()
        decodeStream = nil
        decompressStream = nil
        inputStream = nil
        lastError = nil
    }
    
    // MARK: Sequences and Iterators conformance implementation
    
    public struct AsyncIterator : AsyncIteratorProtocol
    {
        internal var decompressor : PbAppleArchiveDecompressor
        public mutating func next() async throws -> Element? {
            return try decompressor._next()
        }
    }
    
    public __consuming func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(decompressor: self)
    }
    
    public typealias Element = Data
    
    public mutating func nextThrows() throws -> Data? {
        return try _next()
    }
    
    public var lastError : Error?

    public mutating func next() -> Data? {
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
    
    private mutating func makeInputFileStream(_ atPath: String, _ permissions: FilePermissions) throws {
        inputStream = ArchiveByteStream.fileStream(
            path: FilePath(atPath),
            mode: .readOnly,
            options: [.closeOnExec, .nonBlocking],
            permissions: permissions)
    }
    
    private mutating func makeDecompressAndDecodeStreams() throws {
        guard inputStream != nil else {
            throw ArchiveError.invalidValue
        }

        decompressStream = ArchiveByteStream.decompressionStream(readingFrom: inputStream!)
        guard decompressStream != nil else {
            try close()
            throw ArchiveError.invalidValue
        }
        
        decodeStream = ArchiveStream.decodeStream(readingFrom: decompressStream!)
        guard decodeStream != nil else {
            try close()
            throw ArchiveError.invalidValue
        }
    }
    
    private var lastStringPatField = ""
    
    private mutating func _next() throws -> Data? {
        lastStringPatField = ""

        guard let header = try decodeStream?.readHeader() else {
            try close()
            return nil
        }
        
        let patField = header.field(forKey: .init("PAT"))
        if case .string(_, let name) = patField {
            lastStringPatField = name
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

#endif

