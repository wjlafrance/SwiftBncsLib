import Foundation

public struct BnftpRequestComposer {

    private let protocolVersion = 0x100

    let platformIdentifier: BncsPlatformIdentifier
    let productIdentifier: BncsProductIdentifier

    private let bannerIdentifier = 0 as UInt32
    private let bannerFileExtension = 0 as UInt32

    private let startPositionInFile = 0 as UInt32
    private let localFiletime = 0 as UInt64

    let filename: String

    public init(platformIdentifier: BncsPlatformIdentifier = .IntelX86, productIdentifier: BncsProductIdentifier, filename: String) {

        self.platformIdentifier = platformIdentifier
        self.productIdentifier = productIdentifier
        self.filename = filename
    }

    public func build() -> Foundation.Data {

        let baseMessageLength = 33

        var composer = RawMessageComposer()
        composer.write(UInt16(baseMessageLength + filename.lengthOfBytes(using: .ascii)))
        composer.write(UInt16(protocolVersion))
        composer.write(platformIdentifier.rawValue)
        composer.write(productIdentifier.rawValue)
        composer.write(bannerIdentifier)
        composer.write(bannerFileExtension)
        composer.write(startPositionInFile)
        composer.write(localFiletime)
        composer.write(filename)
        return composer.build(messageIdentifier: ())

    }

}

public struct Bnftp2InitialRequestComposer {

    private let protocolVersion = 0x200

    let platformIdentifier: BncsPlatformIdentifier
    let productIdentifier: BncsProductIdentifier

    private let bannerIdentifier = 0 as UInt32
    private let bannerFileExtension = 0 as UInt32

    public init(platformIdentifier: BncsPlatformIdentifier = .IntelX86, productIdentifier: BncsProductIdentifier) {

        self.platformIdentifier = platformIdentifier
        self.productIdentifier = productIdentifier
    }

    public func build() -> Foundation.Data {

        let baseMessageLength = 20

        var composer = RawMessageComposer()
        composer.write(UInt16(baseMessageLength))
        composer.write(UInt16(protocolVersion))
        composer.write(platformIdentifier.rawValue)
        composer.write(productIdentifier.rawValue)
        composer.write(bannerIdentifier)
        composer.write(bannerFileExtension)
        return composer.build(messageIdentifier: ())

    }

}

public struct Bnftp2SecondRequestComposer {

    private let startPositionInFile = 0 as UInt32
    private let localFiletime = 0 as UInt64

    let serverToken: UInt32
    let clientToken = UInt32.random(in: .min ... .max)
    let filename: String
    let cdkey: String

    public init(serverToken: UInt32, filename: String, cdkey: String) {

        self.serverToken = serverToken
        self.filename = filename
        self.cdkey = cdkey
    }

    public func build() -> Foundation.Data {

        var composer = RawMessageComposer()
        composer.write(startPositionInFile)
        composer.write(localFiletime)
        composer.write(clientToken)
        composer.write(try! CdkeyDecodeAlpha26(cdkey: cdkey).hashForAuthCheck(clientToken: clientToken, serverToken: serverToken))
        composer.write(filename)
        return composer.build(messageIdentifier: ())

    }
}
