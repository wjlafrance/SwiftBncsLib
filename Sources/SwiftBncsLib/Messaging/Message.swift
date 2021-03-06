import Foundation

public protocol Message: Equatable {

    var data: Foundation.Data { get }

}

extension Foundation.Data: Message {

    public var data: Foundation.Data {
        return self
    }

}

extension Message {

    //MARK: Equatable

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.data == rhs.data
    }

}
