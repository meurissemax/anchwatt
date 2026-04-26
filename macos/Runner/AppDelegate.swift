import Cocoa
import FlutterMacOS
import IOKit
import IOKit.usb

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

final class UsbMonitor: NSObject, FlutterStreamHandler {
  private var notifyPort: IONotificationPortRef?
  private var matchedIterator: io_iterator_t = 0
  private var terminatedIterator: io_iterator_t = 0
  private var sink: FlutterEventSink?

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    self.sink = events
    start()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    stop()
    self.sink = nil
    return nil
  }

  private func start() {
    let port = IONotificationPortCreate(kIOMainPortDefault)
    self.notifyPort = port

    if let runLoopSource = IONotificationPortGetRunLoopSource(port)?.takeUnretainedValue() {
      CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
    }

    let selfPtr = Unmanaged.passUnretained(self).toOpaque()

    // Matched (connect) — IOServiceMatching is consumed by the call.
    IOServiceAddMatchingNotification(
      port,
      kIOMatchedNotification,
      IOServiceMatching(kIOUSBDeviceClassName),
      { (refCon, iterator) in
        let monitor = Unmanaged<UsbMonitor>.fromOpaque(refCon!).takeUnretainedValue()
        monitor.handleIterator(iterator, type: "connect")
      },
      selfPtr,
      &matchedIterator
    )
    // Drain the initial set silently — these are devices already plugged in at launch.
    drainSilently(matchedIterator)

    // Terminated (disconnect) — fresh matching dictionary required.
    IOServiceAddMatchingNotification(
      port,
      kIOTerminatedNotification,
      IOServiceMatching(kIOUSBDeviceClassName),
      { (refCon, iterator) in
        let monitor = Unmanaged<UsbMonitor>.fromOpaque(refCon!).takeUnretainedValue()
        monitor.handleIterator(iterator, type: "disconnect")
      },
      selfPtr,
      &terminatedIterator
    )
    drainSilently(terminatedIterator)
  }

  private func stop() {
    if matchedIterator != 0 {
      IOObjectRelease(matchedIterator)
      matchedIterator = 0
    }
    if terminatedIterator != 0 {
      IOObjectRelease(terminatedIterator)
      terminatedIterator = 0
    }
    if let port = notifyPort {
      IONotificationPortDestroy(port)
      notifyPort = nil
    }
  }

  private func drainSilently(_ iterator: io_iterator_t) {
    var obj = IOIteratorNext(iterator)
    while obj != 0 {
      IOObjectRelease(obj)
      obj = IOIteratorNext(iterator)
    }
  }

  // The iterator MUST be drained for IOKit to re-arm the next callback,
  // so we always consume every entry — even if we end up coalescing them
  // into a single payload to the Flutter sink.
  private func handleIterator(_ iterator: io_iterator_t, type: String) {
    var obj = IOIteratorNext(iterator)
    var sawAny = false
    while obj != 0 {
      sawAny = true
      IOObjectRelease(obj)
      obj = IOIteratorNext(iterator)
    }
    if sawAny, let sink = sink {
      sink(["type": type])
    }
  }
}
