import Foundation

protocol Message: Equatable {

    var data: Foundation.Data { get }

}

extension Foundation.Data: Message {

    var data: Foundation.Data {
        return self
    }

}

extension Message {

    //MARK: Equatable

    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.data == rhs.data
    }

}
