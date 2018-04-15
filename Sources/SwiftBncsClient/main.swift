import Cocoa
import NIO

enum AppContext {

    static let networkEventLoopGroup = MultiThreadedEventLoopGroup(numThreads: 1)

}

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        print("applicationDidFinishLaunching!")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

NSApplication.shared.delegate = AppDelegate()
NSApp.setActivationPolicy(.regular)

let window = NSWindow(contentViewController: BotInstanceViewController())
window.title = "SwiftBot"

let windowController = NSWindowController(window: window)
windowController.showWindow(nil)

NSApp.run()
