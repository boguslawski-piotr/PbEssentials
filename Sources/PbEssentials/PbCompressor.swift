/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation
import System

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public protocol PbCompressorProtocol
{
    @discardableResult func create(file atPath: String, permissions: FilePermissions?) throws -> Self
    @discardableResult func append(contentsOf url: URL, withName: String?) throws -> Self
    @discardableResult func append(data: Data, withName: String?) throws -> Self
    func close() throws
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public protocol PbDecompressorProtocol
{
    func open(file atPath: String, permissions: FilePermissions?) throws -> Self
    func read() throws -> Data?
    func read(_ name: inout String) throws -> Data?
    func close() throws
}


