/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import CryptoKit
import Foundation
import Security

/// Simple cipher providing encryption / decryption with symetric keys (ChaCha20-Poly1305 algoritm).
///
/// macOS:
/// Methods for storing and retrieving encryption keys to / from keychain require
/// the following lines to be inserted in the [project name].entitlements
///
///     <key>keychain-access-groups</key>
///     <array/>
///
public struct PbSimpleCipher: PbCipher {
    // MARK: Encryption / decryption

    public typealias SymmetricKey = CryptoKit.SymmetricKey

    private let key: SymmetricKey

    public init(_ key: SymmetricKey) {
        self.key = key
    }

    public func encrypt<T>(data: T) throws -> Data where T: DataProtocol {
        try ChaChaPoly.seal(data, using: key).combined
    }

    public func decrypt<T>(data: T) throws -> Data where T: DataProtocol {
        let sealedBox = try ChaChaPoly.SealedBox(combined: data)
        return try ChaChaPoly.open(sealedBox, using: key)
    }

    // MARK: Creation and safe storage of keys

    public enum Device {
        case cloud
        case thisDevice
    }

    public enum Accessibility {
        /// The data in the keychain item can be accessed only while the device is unlocked by the user.
        case whenUnlocked
        /// The data in the keychain item cannot be accessed after a restart until the device has been unlocked once by the user.
        case afterFirstUnlock
    }

    public static func makeKey(using password: String) throws -> SymmetricKey {
        guard let password = password.data(using: .utf8) else { throw CryptoKitError.wrapFailure }
        return SymmetricKey(data: SHA256.hash(data: password))
    }

    public static func storeKey(_ key: SymmetricKey, to name: String, on device: Device = .cloud, accessible: Accessibility = .whenUnlocked) throws {
        let attrAccessible: CFString
        switch accessible {
        case .whenUnlocked:
            attrAccessible = device == .cloud ? kSecAttrAccessibleWhenUnlocked : kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlock:
            attrAccessible = device == .cloud ? kSecAttrAccessibleAfterFirstUnlock : kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }

        let query =
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrLabel: PbSimpleCipher.makeAttrLabel(name),
                kSecAttrAccount: PbSimpleCipher.makeAttrAccount(name),
                kSecValueData: key.dataRepresentation,
                kSecAttrSynchronizable: device == .cloud,
                kSecUseDataProtectionKeychain: true,
                kSecAttrAccessible: attrAccessible,
            ] as [String: Any]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw PbError(status.errorDescription)
        }
    }

    /// Returns `nil` when the key cannot be found or stored data cannot be converted to Data object.
    public static func retrieveKey(from name: String, on device: Device = .cloud) throws -> SymmetricKey? {
        let query =
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrLabel: PbSimpleCipher.makeAttrLabel(name),
                kSecAttrAccount: PbSimpleCipher.makeAttrAccount(name),
                kSecReturnData: true,
                kSecAttrSynchronizable: device == .cloud,
                kSecUseDataProtectionKeychain: true,
            ] as [String: Any]

        var item: CFTypeRef?
        switch SecItemCopyMatching(query as CFDictionary, &item) {
        case errSecSuccess:
            guard let data = item as? Data else { return nil }
            return SymmetricKey(data: data)
        case errSecItemNotFound:
            return nil
        case let status:
            throw PbError(status.errorDescription)
        }
    }

    public static func deleteKey(_ name: String, on device: Device = .cloud) throws {
        let query =
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrLabel: PbSimpleCipher.makeAttrLabel(name),
                kSecAttrAccount: PbSimpleCipher.makeAttrAccount(name),
                kSecAttrSynchronizable: device == .cloud,
                kSecUseDataProtectionKeychain: true,
            ] as [String: Any]

        switch SecItemDelete(query as CFDictionary) {
        case errSecItemNotFound, errSecSuccess:
            break
        case let status:
            throw PbError(status.errorDescription)
        }
    }

    private static func makeAttrLabel(_ name: String) -> String {
        Bundle.main.bundleIdentifier ?? ""
    }

    private static func makeAttrAccount(_ name: String) -> String {
        (Bundle.main.bundleIdentifier ?? "") + ".\(name)"
    }
}

extension ContiguousBytes {
    /// A Data instance created safely from the contiguous bytes without making any copies.
    fileprivate var dataRepresentation: Data {
        return self.withUnsafeBytes { bytes in
            let cfdata = CFDataCreateWithBytesNoCopy(nil, bytes.baseAddress?.assumingMemoryBound(to: UInt8.self), bytes.count, kCFAllocatorNull)
            return ((cfdata as NSData?) as Data?) ?? Data()
        }
    }
}

extension OSStatus {
    fileprivate var errorDescription: String {
        return (SecCopyErrorMessageString(self, nil) as String?) ?? String(self)
    }
}
