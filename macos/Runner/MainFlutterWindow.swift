import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var usbMonitor: UsbMonitor?
  private var systemVolumeMonitor: SystemVolumeMonitor?

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

    let monitor = UsbMonitor()
    let usbChannel = FlutterEventChannel(
      name: "com.anchwatt/usb_events",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    usbChannel.setStreamHandler(monitor)
    self.usbMonitor = monitor

    let volumeMonitor = SystemVolumeMonitor()
    let volumeChannel = FlutterEventChannel(
      name: "com.anchwatt/system_volume",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    volumeChannel.setStreamHandler(volumeMonitor)
    self.systemVolumeMonitor = volumeMonitor

    super.awakeFromNib()
  }
}
