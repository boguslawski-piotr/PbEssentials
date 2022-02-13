/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

public extension Encodable
{
    func encoded(using encoder: PbEncoder = JSONCoder(decoder: nil)) throws -> Data {
        try encoder.encode(self)
    }
}
