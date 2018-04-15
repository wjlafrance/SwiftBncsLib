import Foundation

enum BnftpMessageError: Error {
    case PipeBroken
}


public class BnftpResponseConsumer {

    let inputStream: InputStream

    public var filesize: Int
    public var filename: String

    var fileData: Foundation.Data? = nil

    // For curiosity
    public let responseObject: [String: Any]

    public init(inputStream: InputStream) throws {
        self.inputStream = inputStream

        guard var responseLengthMessage = inputStream.readRawMessage(maxLength: 2), responseLengthMessage.message.count == 2 else {
            throw BnftpMessageError.PipeBroken
        }

        let responseLength = responseLengthMessage.readUInt16()
        guard var responseMessage = inputStream.readRawMessage(maxLength: Int(responseLength) - 2) else {
            throw BnftpMessageError.PipeBroken
        }

        let filetype = responseMessage.readUInt16()
        filesize = Int(responseMessage.readUInt32())
        let bannerIdentifier = responseMessage.readUInt32()
        let bannerFileExtension = responseMessage.readUInt32()
        let filetime = responseMessage.readUInt64()
        filename = responseMessage.readNullTerminatedString()

        responseObject = [
            "filetype": filetype,
            "filesize": filesize,
            "bannerIdentifier": bannerIdentifier,
            "bannerFileExtension": bannerFileExtension,
            "filetime": filetime,
            "filename": filename
        ]
    }

    public func write(path: String) throws {
        if nil == fileData {

            var dataAccumulator = Data()
            while dataAccumulator.count < filesize {
                guard let chunk = inputStream.readData(maxLength: filesize - dataAccumulator.count) else {
                    throw BnftpMessageError.PipeBroken
                }
                dataAccumulator.append(chunk)
            }

            fileData = dataAccumulator
        }

        guard let fileData = fileData else {
            throw BnftpMessageError.PipeBroken
        }
        
        try fileData.write(to: URL(fileURLWithPath: path))
    }
    
}

public class Bnftp2ServerTokenResponseConsumer {

    let inputStream: InputStream

    public let serverToken: UInt32

    public init(inputStream: InputStream) throws {
        self.inputStream = inputStream

        guard var responseData = inputStream.readRawMessage(maxLength: 4) else {
            throw BnftpMessageError.PipeBroken
        }

        serverToken = responseData.readUInt32()
    }

}


public class Bnftp2ResponseConsumer {

    let inputStream: InputStream

    public var filesize: Int
    public var filename: String

    var fileData: Foundation.Data? = nil

    // For curiosity
    public let responseObject: [String: Any]

    public init(inputStream: InputStream) throws {
        self.inputStream = inputStream

        guard var responseLengthMessage = inputStream.readRawMessage(maxLength: 4), responseLengthMessage.message.count == 4 else {
            throw BnftpMessageError.PipeBroken
        }

        let responseLength = responseLengthMessage.readUInt32()
        guard var responseMessage = inputStream.readRawMessage(maxLength: Int(responseLength) - 4) else {
            throw BnftpMessageError.PipeBroken
        }

        filesize = Int(responseMessage.readUInt32())
        let bannerIdentifier = responseMessage.readUInt32()
        let bannerFileExtension = responseMessage.readUInt32()
        let filetime = responseMessage.readUInt64()
        filename = responseMessage.readNullTerminatedString()

        responseObject = [
            "filesize": filesize,
            "bannerIdentifier": bannerIdentifier,
            "bannerFileExtension": bannerFileExtension,
            "filetime": filetime,
            "filename": filename
        ]
    }

    public func write(path: String) throws {
        if nil == fileData {

            var dataAccumulator = Data()
            while dataAccumulator.count < filesize {
                guard let chunk = inputStream.readData(maxLength: filesize - dataAccumulator.count) else {
                    throw BnftpMessageError.PipeBroken
                }
                dataAccumulator.append(chunk)
            }

            fileData = dataAccumulator
        }

        guard let fileData = fileData else {
            throw BnftpMessageError.PipeBroken
        }

        try fileData.write(to: URL(fileURLWithPath: path))
    }

}
