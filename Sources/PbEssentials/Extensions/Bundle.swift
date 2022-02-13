/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

extension Bundle {
    @inlinable
    public var name: String {
        let v = object(forInfoDictionaryKey: "CFBundleName") as? String
        return v ?? ""
    }

    @inlinable
    public var displayName: String {
        let v = object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        return L(v ?? self.name)
    }

    @inlinable
    public var version: String {
        let v = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return L(v ?? "")
    }

    @inlinable
    public var copyright: String {
        let v = object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
        return L(v ?? "")
    }

    @inlinable
    public func L(_ keyValue: String) -> String {
        return localizedString(forKey: keyValue, value: keyValue, table: nil)
    }
}
