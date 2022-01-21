import XCTest
import CryptoKit
@testable import PbEssentials

// MARK: Basic tests

final class PbEssentialsTests: XCTestCase
{
    func testPbSimpleCipher() throws {
        guard let password = "this is some @&^ password )9@".data(using: .utf8) else {
            throw PbError("Can't create data object from password :(")
        }

        let secret = "This is a very sensitive message ;)"
        
        func makeKey(_ password : Data) -> SymmetricKey {
            let hash = SHA256.hash(data: password)
            let key = SymmetricKey(data: hash)
            return key
        }
        
        let ekey = makeKey(password)
        let encryptedSecret = try PbSimpleCipher(ekey).encrypt(secret)
        
        let dkey = makeKey(password)
        let decryptedSecret = try PbSimpleCipher(dkey).decrypt(itemOf: String.self, from: encryptedSecret)
        
        dbg(decryptedSecret, "==", secret)
        
        XCTAssert(decryptedSecret == secret)
    }
}
