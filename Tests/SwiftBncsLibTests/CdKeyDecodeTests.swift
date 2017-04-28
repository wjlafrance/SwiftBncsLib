import XCTest
@testable import SwiftBncsLib

class CdKeyDecodeTests: XCTestCase {

    func test() {
        let testCases: [(String, UInt32, UInt32, [UInt8])] = [
            ("YKY7EPR664G6DWG7CV8REKVEGK", 0x0E, 0x005A8478,
                [0x52, 0x15, 0x16, 0x88, 0xC6, 0x78, 0x90, 0x49, 0x6D, 0x5F]),
            ("ZJEMBXPXZ4NFJDRTK2E2899RH9", 0x0E, 0x000F298C,
                [0xFC, 0x7F, 0xE8, 0xD0, 0x72, 0x37, 0x39, 0xAC, 0xC8, 0x53])
        ]

        for (key, prod, val1, val2) in testCases {
            let x = CdKeyDecode(cdkey: key)
            XCTAssertEqual(x.productValue, prod)
            XCTAssertEqual(x.value1, val1)
            XCTAssertEqual(x.value2, val2)
        }
    }

}
