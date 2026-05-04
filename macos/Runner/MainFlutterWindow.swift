import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var usbMonitor: UsbMonitor?
  private var systemVolumeMonitor: SystemVolumeMonitor?
  private var chargerMonitor: ChargerMonitor?
  private var externalDisplayMonitor: ExternalDisplayMonitor?
  private var headphonesMonitor: HeadphonesMonitor?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    self.title = "Anchwatt"

    let size = NSSize(width: 340, height: 450)
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

    let charger = ChargerMonitor()
    let chargerChannel = FlutterEventChannel(
      name: "com.anchwatt/charger_events",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    chargerChannel.setStreamHandler(charger)
    self.chargerMonitor = charger

    let externalDisplay = ExternalDisplayMonitor()
    let externalDisplayChannel = FlutterEventChannel(
      name: "com.anchwatt/external_display_events",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    externalDisplayChannel.setStreamHandler(externalDisplay)
    self.externalDisplayMonitor = externalDisplay

    let headphones = HeadphonesMonitor()
    let headphonesChannel = FlutterEventChannel(
      name: "com.anchwatt/headphones_events",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    headphonesChannel.setStreamHandler(headphones)
    self.headphonesMonitor = headphones

    let backgroundModeController = BackgroundModeController(window: self)
    (NSApp.delegate as? AppDelegate)?.backgroundModeController = backgroundModeController

    super.awakeFromNib()
  }
}
