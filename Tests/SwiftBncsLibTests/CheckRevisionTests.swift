
import XCTest
@testable import SwiftBncsLib

class CheckRevisionTests: XCTestCase {

    func testD2dv() throws {
        print(FileManager.default.currentDirectoryPath)

        let (version, hash, info) = try CheckRevision.hash(
            mpqFileNumber: 7,
            challenge: "B=676679339 C=4153317847 A=2798954125 4 A=A^S B=B-C C=C+A A=A^B",
            files: [
                URL(fileURLWithPath: "./extern/hashfiles/D2DV/Game.exe")
            ]
        )

        XCTAssertEqual(version, 0x010E0300)
        XCTAssertEqual(hash,    0xC30399D7)
        XCTAssertEqual(info,    "Game.exe 05/31/16 19:02:32 3614696")
    }

    func testD2xp() throws {
        let (version, hash, info) = try CheckRevision.hash(
            mpqFileNumber: 0,
            challenge: "A=1262984606 B=3951383673 C=2230464239 4 A=A+S B=B-C C=C^A A=A-B",
            files: [
                URL(fileURLWithPath: "./extern/hashfiles/D2XP/Game.exe")
            ]
        )

        XCTAssertEqual(version, 0x010E0300)
        XCTAssertEqual(hash,    0x2231ACA8)
        XCTAssertEqual(info,    "Game.exe 05/31/16 19:02:24 3618792")
    }

}
