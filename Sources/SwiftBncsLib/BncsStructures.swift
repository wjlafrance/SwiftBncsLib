public struct BncsChatEvent {

    public let identifier: BncsChatEventIdentifier
    public let username: String
    public let text: String
    public let flags: UInt32
    public let ping: UInt32

    public init(identifier: BncsChatEventIdentifier, username: String, text: String, flags: UInt32, ping: UInt32) {
        self.identifier = identifier
        self.username = username
        self.text = text
        self.flags = flags
        self.ping = ping
    }

}
