import Cocoa

class BotInstanceViewController: NSViewController {

    let botInstance = BotInstance()

    override func loadView() {
        print("BotInstanceViewController::loadView")
        self.view = NSView(frame: NSRect(x: 200, y: 200, width: 400, height: 400))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        print("BotInstanceViewController::viewDidLoad")
    }
}
