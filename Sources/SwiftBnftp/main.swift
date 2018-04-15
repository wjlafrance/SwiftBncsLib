
import Foundation
import SwiftBncsLib

let DefaultOptions = [
    "bncs-addr": "asia.battle.net",
    "bncs-port": "6112",
    "prod-id": "VD2D",
    "plat-id": "68XI",
    "filename": "tos-unicode.txt",
    "output-dir": NSTemporaryDirectory()
]

func loadOptionsFromCommandLine() -> [String: String] {
    if CommandLine.arguments.count == 2 && CommandLine.arguments[1] == "--help" {
        print("Usage: swiftbnftp [--optionname optionvalue]..")
        exit(0)
    }

    guard CommandLine.arguments.count % 2 == 1 else {
        preconditionFailure("Invalid argument count, see --help")
    }

    var options = DefaultOptions

    for i in stride(from: 1, to: CommandLine.arguments.count, by: 2) {

        let lhs = CommandLine.arguments[i]
        let rhs = CommandLine.arguments[i + 1]

        guard lhs.hasPrefix("--") else {
            preconditionFailure("Invalid argument format")
        }

        options[lhs.substring(from: lhs.index(lhs.startIndex, offsetBy: 2))] = rhs
    }

    return options
}

func createStreamPair(host: String, port: Int) -> (InputStream, OutputStream) {
    var inputStream: InputStream? = nil, outputStream: OutputStream? = nil
    Foundation.Stream.getStreamsToHost(withName: host, port: port, inputStream: &inputStream, outputStream: &outputStream)
    outputStream!.open()
    inputStream!.open()
    return (inputStream!, outputStream!)
}

let SessionOptions = loadOptionsFromCommandLine()

print("Compiled default options: \(DefaultOptions)")
print("Options for this session: \(SessionOptions)")

guard let bncsAddr        = SessionOptions["bncs-addr"],
    let bncsPortString  = SessionOptions["bncs-port"],
    let filename        = SessionOptions["filename"],
    let outputDirectory = SessionOptions["output-dir"],
    let prodIdString    = SessionOptions["prod-id"],
    let platIdString    = SessionOptions["plat-id"],
    let bncsPort = Int(bncsPortString),
    let prodId = SwiftBncsLib.BncsProductIdentifier(stringRepresentation: prodIdString),
    let platId = SwiftBncsLib.BncsPlatformIdentifier(stringRepresentation: platIdString)
    else {
        preconditionFailure("An option is missing or illegal. Debug me to find out why.")
}

print("[BNFTP] Connecting..")

let (inputStream, outputStream) = createStreamPair(host: bncsAddr, port: bncsPort)

outputStream.write(byte: BncsProtocolIdentifier.FileTransferProtocol.rawValue)

let request = BnftpRequestComposer(platformIdentifier: platId, productIdentifier: prodId, filename: filename).build()

print("[BNFTP] Request sent")
outputStream.write(data: request)

guard let consumer = try? BnftpResponseConsumer(inputStream: inputStream) else {
    print("[BNFTP] Bad response :(")
    exit(0)
}

let outputPath = (outputDirectory as NSString).appendingPathComponent(consumer.filename)
print("[BNFTP] Received response: \(consumer.filesize) bytes")
do {
    try consumer.write(path: outputPath)
    print("[BNFTP] Wrote file to \(outputPath)")
} catch(let error) {
    print("[BNFTP] Error writing file: \(error)")
}
