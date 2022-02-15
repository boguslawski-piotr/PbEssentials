/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Compression
import Foundation

public struct PbSimpleCompressorDecompressor: PbCompressorDecompressor {
    public var compression: PbCompression
    public var pageSize: Int

    public init(compression: PbCompression = .strong, pageSize: Int = 32768) {
        self.compression = compression
        self.pageSize = pageSize
    }

    public func compress(data: Data) throws -> Data {
        var index = 0
        let filter = try InputFilter(.compress, using: compressionAlgorithm) { (length: Int) -> Data? in
            return self.read(from: data, count: length, updating: &index)
        }
        return try process(filter)
    }
    
    public func decompress(data: Data) throws -> Data {
        var index = 0
        let filter = try InputFilter(.decompress, using: compressionAlgorithm) { (length: Int) -> Data? in
            return self.read(from: data, count: length, updating: &index)
        }
        return try process(filter)
    }

    private var compressionAlgorithm: Algorithm { compression == .fast ? .lz4 : .lzma }

    private func read(from data: Data, count length: Int, updating index: inout Int) -> Data? {
        let length = min(length, data.count - index)
        let subdata = data.subdata(in: index..<index + length)
        index += length
        return subdata
    }

    private func process(_ filter: InputFilter<Data>) throws -> Data {
        var result = Data()
        while let page = try filter.readData(ofLength: pageSize) {
            result.append(page)
        }
        return result
    }
}
