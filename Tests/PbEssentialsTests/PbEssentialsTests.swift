import XCTest
import CryptoKit
@testable import PbEssentials

// MARK: Basic tests

final class PbEssentialsTests: XCTestCase
{
    func testPbSimpleCipher() throws {
        let password = "this is THE @&^ password )9@"
        let secret = "This is a very sensitive message ;)"
        
        let ekey = try PbSimpleCipher.makeKey(using: password)
        let encryptedSecret = try PbSimpleCipher(ekey).encrypt(secret)
        
        let dkey = try PbSimpleCipher.makeKey(using: password)
        let decryptedSecret = try PbSimpleCipher(dkey).decrypt(itemOf: String.self, from: encryptedSecret)
        
        dbg(decryptedSecret, "==", secret)
        XCTAssert(decryptedSecret == secret)
    }
}
