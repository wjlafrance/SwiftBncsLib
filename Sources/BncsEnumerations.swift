enum BncsMessageIdentifier: UInt8 {
    case Null      = 0x00
    case Registry  = 0x18
    case Ping      = 0x25
    case AuthInfo  = 0x50
    case AuthCheck = 0x51
    case Unknown   = 0xFF
}

enum BncsPlatformIdentifier: UInt32 {
    case IntelX86       = 0x49583836 // IX86
    case PowerMacintosh = 0x504d4143 // PMAC
    case IntelMacintosh = 0x584d4143 // XMAC
}

enum BncsLanguageIdentifier: UInt32 {
    case Nil = 0
    case EnglishUnitedStates = 0x656e5553 // enUS
}

enum BncsProductIdentifier: UInt32 {

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
        let invalidBncsClients: [BncsProductIdentifier] = [.Telnet, .Starcraft, .StarcraftExpansion, .StarcraftShareware, .StarcraftJapan, .DiabloShareware, .DiabloBeta, .DiabloStressTest, .Diablo2StressTest, .Warcraft3Demo]

        return !invalidBncsClients.contains(self)
    }

}
