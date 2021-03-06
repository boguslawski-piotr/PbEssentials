import Combine
import CryptoKit
import XCTest

@testable import PbEssentials

// MARK: Basic tests

final class PbEssentialsTests: XCTestCase {
    func testPbSimpleCipher() throws {
        let password = "this is THE @&^ password )9@"
        let secret = "This is a very sensitive message ;)"

        let ekey = try PbSimpleCipher.makeKey(using: password)
        let encryptedSecret = try secret.encrypted(using: PbSimpleCipher(ekey))

        let dkey = try PbSimpleCipher.makeKey(using: password)
        let decryptedSecret = try encryptedSecret.decrypted(as: String.self, using: PbSimpleCipher(dkey))

        dbg(decryptedSecret, "==", secret)
        XCTAssert(decryptedSecret == secret)
    }

    func testPbSimpleCompressorDecompressor() throws {
        let compressorDecompressor = PbSimpleCompressor(compression: .fast)

        let sourceString =
            """
            Lorem ipsum dolor sit amet consectetur adipiscing elit mi
            nibh ornare proin blandit diam ridiculus, faucibus mus
            dui eu vehicula nam donec dictumst sed vivamus bibendum
            aliquet efficitur. Felis imperdiet sodales dictum morbi
            vivamus augue dis duis aliquet velit ullamcorper porttitor,
            lobortis dapibus hac purus aliquam natoque iaculis blandit
            montes nunc pretium.
            """
        let sourceData = sourceString.data(using: .utf8)!

        let cdata = try compressorDecompressor.compress(data: sourceData)
        let destinationData = try compressorDecompressor.decompress(data: cdata)

        XCTAssert(destinationData == sourceData)
        XCTAssert(String(data: destinationData, encoding: .utf8) == sourceString)

        let cdata1 = try sourceString.compressed(using: compressorDecompressor)
        let destinationString = try cdata1.decompressed(as: String.self, using: compressorDecompressor)
        
        dbg(destinationString)
        XCTAssert(destinationString == sourceString)
    }
}

// MARK:

final class PbObservableObjectPbPublishedTests: XCTestCase {
    var c1, c2, c3, c4: AnyCancellable?

    func test1() {
        class Weather: PbObservableObject {
            @PbPublished var temperature: Int = 20
            @PbPublished var temperature2: Double = 10.0
        }

        let weather = Weather()

        var weatherWillChange = 0
        var weatherDidChange = 0
        var temperatureChanges = 0

        c1 = weather.objectWillChange
            .sink {
                dbg("Weather will change")
                weatherWillChange += 1
            }
        c2 = weather.objectDidChange
            .sink {
                dbg("Weather did change")
                weatherDidChange += 1
            }
        c3 = weather.$temperature
            .sink {
                dbg("(will) Temperature now: \($0)")
                temperatureChanges += 1
            }

        weather.temperature = 25
        weather.temperature2 = 15

        try? Task.blocking {
            try await Task.sleep(for: .seconds(1))
            weather.temperature2 = 10
            weather.temperature = 20
        }

        XCTAssert(weatherWillChange == 4)
        XCTAssert(weatherDidChange == 4)

        XCTAssert(temperatureChanges == 3)  // because property publisher works different than common objectWill/DidChange
    }

    func test2() {
        class Weather: PbObservableObject {
            init() {}
        }

        let weather = Weather()
        var test = false

        c1 = weather.objectWillChange
            .sink {
                dbg("test2: Weather will change")
                test = true
            }

        weather.objectWillChange.send()

        XCTAssert(test)
    }
}

// MARK:

final class PbObservableTests: XCTestCase {
    var c1, c2, c3, c4: AnyCancellable?
    
    class Cos: PbObservableObject {
        @PbPublished var test = 1
    }

    func test1() {
        @PbObservableCollection var arr: [Cos] = []
        var changes = 0
        
        c1 = _arr.objectWillChange
            .sink {
                dbg("changed")
                changes += 1
            }
        
        arr.append(Cos())
        arr[0].test = 2
        arr.remove(at: 0)
        
        XCTAssert(changes == 3)
    }

    func test2() {
        @PbObservableDictionary var dict: [Int : Cos] = [:]
        var changes = 0
        
        c1 = _dict.objectWillChange
            .sink {
                dbg("changed")
                changes += 1
            }
        
        dict[1] = Cos()
        dict[1]?.test = 2
        dict.removeValue(forKey: 1)
        
        XCTAssert(changes == 3)
    }
}

