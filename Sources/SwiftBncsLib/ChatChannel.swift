import Foundation

public struct ChatParticipant {

    let username: String
    let flags: UInt32

}


public struct ChatChannel {

    var name: String

    var participants = [ChatParticipant]()

    public init(name: String) {
        self.name = name
    }

    mutating func processChatEvent(_ chatEvent: BncsChatEvent) {

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
