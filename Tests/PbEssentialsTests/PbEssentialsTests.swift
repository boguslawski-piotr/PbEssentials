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
        let encryptedSecret = try PbSimpleCipher(ekey).encrypt(secret)

        let dkey = try PbSimpleCipher.makeKey(using: password)
        let decryptedSecret = try PbSimpleCipher(dkey).decrypt(itemOf: String.self, from: encryptedSecret)

        dbg(decryptedSecret, "==", secret)
        XCTAssert(decryptedSecret == secret)
    }

    func testPbSimpleArchiver() throws {
        let archiver = PbSimpleArchiver(compression: .fast)

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

        let cdata = try archiver.compress(data: sourceData)
        let destinationData = try archiver.decompress(data: cdata)

        XCTAssert(destinationData == sourceData)
        XCTAssert(String(data: destinationData, encoding: .utf8) == sourceString)

        let cdata1 = try archiver.compress(sourceString)
        let destinationString = try archiver.decompress(itemOf: String.self, from: cdata1)
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
