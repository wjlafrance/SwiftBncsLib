public enum BncsMessageIdentifier: UInt8 {

    case Null           = 0x00
    case EnterChat      = 0x0A
    case JoinChannel    = 0x0C
    case ChatCommand    = 0x0E
    case ChatEvent      = 0x0F
    case Registry       = 0x18
    case Ping           = 0x25
    case LoginResponse2 = 0x3A
    case RequiredWork   = 0x4C
    case AuthInfo       = 0x50
    case AuthCheck      = 0x51
    case SetEmail       = 0x59

    case None           = 0xFF
}


public enum BncsProtocolIdentifier: UInt8 {

    case ChatService = 0x01
    case FileTransferProtocol = 0x02

}


public enum BncsPlatformIdentifier: UInt32 {

    case IntelX86       = 0x49583836 // IX86
    case PowerMacintosh = 0x504d4143 // PMAC
    case IntelMacintosh = 0x584d4143 // XMAC

    public init?(stringRepresentation: String) {
        assert(stringRepresentation.count == 4)

        guard let x = BncsPlatformIdentifier(rawValue: FourCC(stringRepresentation: stringRepresentation).rawValue) else {
            return nil
        }

        self = x
    }
}


public enum BncsLanguageIdentifier: UInt32 {

    case Nil = 0
    case EnglishUnitedStates = 0x656e5553 // enUS

}


public enum BncsProductIdentifier: UInt32 {

    case Telnet             = 0x43484154 // CHAT
    case StarcraftShareware = 0x53534852 // SSHR
    case StarcraftJapan     = 0x4a535452 // JSTR
    case Starcraft          = 0x53544152 // STAR
    case StarcraftExpansion = 0x53455850 // SEXP
    case DiabloShareware    = 0x44534852 // DSHR
    case DiabloBeta         = 0x44494142 // DIAB
    case DiabloStressTest   = 0x44545354 // DTST
    case Diablo             = 0x4452544c // DRTL
    case Diablo2StressTest  = 0x44325354 // D2ST
    case Diablo2            = 0x44324456 // D2DV
    case Diablo2Expansion   = 0x44325850 // D2XP
    case Warcraft2          = 0x5732424e // W2BN
    case Warcraft3Demo      = 0x5733444d // W3DM
    case Warcraft3          = 0x57415233 // WAR3
    case Warcraft3Expansion = 0x57335850 // W3XP

    var isValidBncsClient: Bool {
        let invalidBncsClients: [BncsProductIdentifier] = [
            .Telnet,
            .Starcraft,
            .StarcraftExpansion,
            .StarcraftShareware,
            .StarcraftJapan,
            .DiabloShareware,
            .DiabloBeta,
            .DiabloStressTest,
            .Diablo2StressTest,
            .Warcraft3Demo
        ]

        return !invalidBncsClients.contains(self)
    }

    public init?(stringRepresentation: String) {
        assert(stringRepresentation.count == 4)

        guard let x = BncsProductIdentifier(rawValue: FourCC(stringRepresentation: stringRepresentation).rawValue) else {
            return nil
        }

        self = x
    }

}

public enum BncsChatEvent: UInt32 {

    case showUser            = 0x01
    case join                = 0x02
    case leave               = 0x03
    case whisper             = 0x04
    case talk                = 0x05
    case broadcast           = 0x06
    case channel             = 0x07
    // 0x08
    case userflags           = 0x09
    case whisperSent         = 0x0A
    // 0x0b
    // 0x0c
    case channelFull         = 0x0D
    case channelDoesNotExist = 0x0E
    case channelRestricted   = 0x0F
    // 0x10
    // 0x11
    case info                = 0x12
    case error               = 0x13
    // 0x14
//    case ignore = 0x15 // defunct
//    case accept = 0x16 // defunct
    case emote               = 0x17

}
