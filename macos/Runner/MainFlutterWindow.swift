import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    self.title = "Anchwatt"

    let size = NSSize(width: 320, height: 420)
    self.setContentSize(size)
    self.contentMinSize = size
    self.contentMaxSize = size
    self.center()
    self.styleMask.remove(.resizable)
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask.insert(.fullSizeContentView)
    self.isMovableByWindowBackground = true
    self.standardWindowButton(.zoomButton)?.isEnabled = false
    self.collectionBehavior.remove(.fullScreenPrimary)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
