import Foundation

public struct ChatParticipant {

    public let username: String

    // TODO: Make BattleNetFlags enum
    public let flags: UInt32

}

public class ChatChannel {

    public var name: String

    public var participants = [ChatParticipant]()

    public init(name: String) {
        self.name = name
    }

    public func processChatEvent(_ chatEvent: BncsChatEvent) {

        switch chatEvent.identifier {

            case .showUser:
                participants.append(ChatParticipant(
                    username: chatEvent.username,
                    flags: chatEvent.flags
                ))

            case .join:
                participants.append(ChatParticipant(
                    username: chatEvent.username,
                    flags: chatEvent.flags
                ))

            case .leave:
                if let index = participants.index(where: { $0.username == chatEvent.username }) {
                    participants.remove(at: index)
                }

            case .channel:
                name = chatEvent.text
                participants.removeAll()

            default:
                print("unhandled chatevent! \(chatEvent)")
        }

    }

}
