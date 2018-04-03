import XCTest
@testable import SwiftBncsLib

class ChatChannelTestsTests: XCTestCase {

    let mockParticipants = [
        ChatParticipant(username: "joe)x86(", flags: 0),
        ChatParticipant(username: "joe)x86(#2", flags: 0),
    ]

    func testRetainsName() {
        let testChannelName = "Diablo II USA-3"

        let x = ChatChannel(name: testChannelName)

        XCTAssertEqual(testChannelName, x.name, "name is retained from init")
    }

    // ChatEvent: BncsChatEvent(identifier: SwiftBncsLib.BncsChatEventIdentifier.channel, username: "joe)x86(", text: "Diablo II USA-3", flags: 1, ping: 47)

    func testHandlesChannelChange() {
        let testChannelName = "Diablo II USA-3"

        var x = ChatChannel(name: "x")
        x.participants = mockParticipants

        x.processChatEvent(BncsChatEvent(
            identifier: .channel,
            username: "joe)x86(",
            text: testChannelName,
            flags: 1,
            ping: 47
        ))

        XCTAssertEqual(testChannelName, x.name, "channel name updated")
        XCTAssertEqual(0, x.participants.count, "channel users removed")
    }

    // ChatEvent: BncsChatEvent(identifier: SwiftBncsLib.BncsChatEventIdentifier.showUser, username: "jalak#USEast*jalak_melee", text: "PX2DUSEast,jalak,>\u{02}\u{02}\u{03}\u{01}\u{04}ÿ^\u{03}\u{03}ÿ\u{04}Qÿÿÿÿÿÿÿÿÿÿ[èÿÿÿÿÿ", flags: 0, ping: 47)
    // ChatEvent: BncsChatEvent(identifier: SwiftBncsLib.BncsChatEventIdentifier.showUser, username: "*joe)x86(", text: "VD2D", flags: 0, ping: 47)

    func testHandlesShowUser() {
        let testUsername = "*joe)x86("
        let testFlags = 0 as UInt32

        var x = ChatChannel(name: "x")

        XCTAssertEqual(0, x.participants.count, "initial condition")

        x.processChatEvent(BncsChatEvent(
            identifier: .showUser,
            username: testUsername,
            text: "VD2D",
            flags: testFlags,
            ping: 47
        ))

        XCTAssertEqual(1, x.participants.count, "user appears in channel")
        XCTAssertEqual(testUsername, x.participants[0].username, "user name is correct")
        XCTAssertEqual(testFlags, x.participants[0].flags, "flags is correct")
    }

    // ChatEvent: BncsChatEvent(identifier: SwiftBncsLib.BncsChatEventIdentifier.join, username: "*joe)x86(#Azeroth", text: "PX3W 1R3W 0", flags: 0, ping: 375)
    func testHandlesJoin() {
        let testUsername = "testUsername"
        let testUsername2 = "testUsername2"
        let testFlags = 0 as UInt32
        let testFlags2 = 1 as UInt32

        var x = ChatChannel(name: "x")

        XCTAssertEqual(0, x.participants.count, "initial condition")

        x.processChatEvent(BncsChatEvent(
            identifier: .join,
            username: testUsername,
            text: "PX3W 1R3W 0",
            flags: testFlags,
            ping: 375
        ))

        x.processChatEvent(BncsChatEvent(
            identifier: .join,
            username: testUsername2,
            text: "PX3W 1R3W 0",
            flags: testFlags2,
            ping: 375
        ))

        XCTAssertEqual(2, x.participants.count, "both users appear in channel")
        XCTAssertEqual(testUsername, x.participants[0].username, "user name is correct")
        XCTAssertEqual(testFlags, x.participants[0].flags, "flags is correct")
        XCTAssertEqual(testUsername2, x.participants[1].username, "user name is correct")
        XCTAssertEqual(testFlags2, x.participants[1].flags, "flags is correct")
    }


    // ChatEvent: BncsChatEvent(identifier: SwiftBncsLib.BncsChatEventIdentifier.leave, username: "*joe)x86(#Azeroth", text: "", flags: 0, ping: 375)

    func testHandlesLeave() {
        var x = ChatChannel(name: "x")
        x.participants = mockParticipants

        XCTAssertEqual(2, x.participants.count, "initial condition")

        x.processChatEvent(BncsChatEvent(
            identifier: .leave,
            username: mockParticipants[0].username,
            text: "",
            flags: 0,
            ping: 375
        ))

        XCTAssertEqual(1, x.participants.count, "user removed")
        XCTAssertEqual(mockParticipants[1].username, x.participants[0].username, "correct user remains in channel")
    }


}

