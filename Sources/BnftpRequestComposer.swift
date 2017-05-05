import Foundation

struct BnftpRequestComposer {

    private let protocolVersion = 0x100

    var platformIdentifier: BncsPlatformIdentifier = .IntelX86
    var productIdentifier: BncsProductIdentifier = .StarcraftJapan

    private let bannerIdentifier = 0 as UInt32
    private let bannerFileExtension = 0 as UInt32

    private let startPositionInFile = 0 as UInt32
    private let localFiletime = 0 as UInt64

    var filename: String

    func build() -> Foundation.Data {

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
