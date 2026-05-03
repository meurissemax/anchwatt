import Cocoa
import CoreAudio
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
  // Registry entry IDs of USB devices currently considered connected. A composite
  // device (phone, dock, hub) can surface several IOUSBDevice services across
  // separate IOKit callbacks during enumeration; tracking IDs lets us emit one
  // Flutter event per real connect/disconnect transition instead of one per match.
  private var connectedDeviceIDs: Set<UInt64> = []

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
    // We have no visibility on devices plugged/unplugged while we were not
    // listening — resync from scratch using the initial iterator drain below.
    connectedDeviceIDs.removeAll()

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
    // Drain the initial set silently and record IDs — these are devices already
    // plugged in at registration time and should not trigger a Flutter event.
    drainAndRecord(matchedIterator)

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

  private func drainAndRecord(_ iterator: io_iterator_t) {
    var obj = IOIteratorNext(iterator)
    while obj != 0 {
      if let id = registryEntryID(of: obj) {
        connectedDeviceIDs.insert(id)
      }
      IOObjectRelease(obj)
      obj = IOIteratorNext(iterator)
    }
  }

  // The iterator MUST be drained for IOKit to re-arm the next callback,
  // so we always consume every entry — but we only emit a single Flutter
  // event when at least one device ID actually transitions in our set.
  private func handleIterator(_ iterator: io_iterator_t, type: String) {
    var didTransition = false
    var obj = IOIteratorNext(iterator)
    while obj != 0 {
      if let id = registryEntryID(of: obj) {
        switch type {
        case "connect":
          if connectedDeviceIDs.insert(id).inserted {
            didTransition = true
          }
        case "disconnect":
          if connectedDeviceIDs.remove(id) != nil {
            didTransition = true
          }
        default:
          break
        }
      }
      IOObjectRelease(obj)
      obj = IOIteratorNext(iterator)
    }
    if didTransition, let sink = sink {
      sink(["type": type])
    }
  }

  private func registryEntryID(of service: io_service_t) -> UInt64? {
    var id: UInt64 = 0
    let status = IORegistryEntryGetRegistryEntryID(service, &id)
    return status == KERN_SUCCESS ? id : nil
  }
}

final class SystemVolumeMonitor: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private var currentDeviceID: AudioDeviceID = AudioDeviceID(kAudioObjectUnknown)
  private var defaultDeviceListener: AudioObjectPropertyListenerBlock?
  private var volumeListeners: [(AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)] = []
  private var muteListener: (AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)?
  private let listenerQueue: DispatchQueue = DispatchQueue.main

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
    currentDeviceID = resolveDefaultOutputDevice()
    emitCurrentState()
    attachDefaultDeviceListener()
    if currentDeviceID != AudioDeviceID(kAudioObjectUnknown) {
      attachDeviceListeners(deviceID: currentDeviceID)
    }
  }

  private func stop() {
    detachDeviceListeners(deviceID: currentDeviceID)
    detachDefaultDeviceListener()
    currentDeviceID = AudioDeviceID(kAudioObjectUnknown)
  }

  // CoreAudio listener blocks fire on `listenerQueue` (main), so reads and
  // sink dispatches are guaranteed to happen on the main thread.
  private func emitCurrentState() {
    let deviceID = currentDeviceID
    let volume: Double
    let muted: Bool
    if deviceID == AudioDeviceID(kAudioObjectUnknown) {
      volume = 0
      muted = false
    } else {
      volume = readVolume(deviceID: deviceID)
      muted = readMuted(deviceID: deviceID)
    }
    sink?(["volume": volume, "muted": muted])
  }

  private func resolveDefaultOutputDevice() -> AudioDeviceID {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDefaultOutputDevice,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var deviceID = AudioDeviceID(kAudioObjectUnknown)
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)
    let status = AudioObjectGetPropertyData(
      AudioObjectID(kAudioObjectSystemObject),
      &address,
      0,
      nil,
      &size,
      &deviceID
    )
    return status == noErr ? deviceID : AudioDeviceID(kAudioObjectUnknown)
  }

  private func attachDefaultDeviceListener() {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDefaultOutputDevice,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
      guard let self = self else { return }
      let oldID = self.currentDeviceID
      let newID = self.resolveDefaultOutputDevice()
      if newID == oldID {
        return
      }
      self.detachDeviceListeners(deviceID: oldID)
      self.currentDeviceID = newID
      if newID != AudioDeviceID(kAudioObjectUnknown) {
        self.attachDeviceListeners(deviceID: newID)
      }
      self.emitCurrentState()
    }
    self.defaultDeviceListener = block
    AudioObjectAddPropertyListenerBlock(
      AudioObjectID(kAudioObjectSystemObject),
      &address,
      listenerQueue,
      block
    )
  }

  private func detachDefaultDeviceListener() {
    guard let block = defaultDeviceListener else { return }
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDefaultOutputDevice,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    AudioObjectRemovePropertyListenerBlock(
      AudioObjectID(kAudioObjectSystemObject),
      &address,
      listenerQueue,
      block
    )
    defaultDeviceListener = nil
  }

  // Some output devices do not expose the "main" volume element (element 0)
  // and only publish per-channel volumes (typically channels 1 and 2). We
  // attach to whichever combination is available so the pill keeps tracking.
  private func attachDeviceListeners(deviceID: AudioDeviceID) {
    for var address in volumeAddresses(deviceID: deviceID) {
      let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
        self?.emitCurrentState()
      }
      let status = AudioObjectAddPropertyListenerBlock(deviceID, &address, listenerQueue, block)
      if status == noErr {
        volumeListeners.append((address, block))
      }
    }

    var muteAddress = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyMute,
      mScope: kAudioDevicePropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )
    if AudioObjectHasProperty(deviceID, &muteAddress) {
      let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
        self?.emitCurrentState()
      }
      let status = AudioObjectAddPropertyListenerBlock(deviceID, &muteAddress, listenerQueue, block)
      if status == noErr {
        muteListener = (muteAddress, block)
      }
    }
  }

  private func detachDeviceListeners(deviceID: AudioDeviceID) {
    if deviceID != AudioDeviceID(kAudioObjectUnknown) {
      for (var address, block) in volumeListeners {
        AudioObjectRemovePropertyListenerBlock(deviceID, &address, listenerQueue, block)
      }
      if var entry = muteListener {
        AudioObjectRemovePropertyListenerBlock(deviceID, &entry.0, listenerQueue, entry.1)
      }
    }
    volumeListeners.removeAll()
    muteListener = nil
  }

  private func volumeAddresses(deviceID: AudioDeviceID) -> [AudioObjectPropertyAddress] {
    var mainAddress = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyVolumeScalar,
      mScope: kAudioDevicePropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )
    if AudioObjectHasProperty(deviceID, &mainAddress) {
      return [mainAddress]
    }
    var fallbacks: [AudioObjectPropertyAddress] = []
    for channel: AudioObjectPropertyElement in [1, 2] {
      var address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyVolumeScalar,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: channel
      )
      if AudioObjectHasProperty(deviceID, &address) {
        fallbacks.append(address)
      }
    }
    return fallbacks
  }

  private func readVolume(deviceID: AudioDeviceID) -> Double {
    let addresses = volumeAddresses(deviceID: deviceID)
    if addresses.isEmpty {
      return 0
    }
    var sum: Double = 0
    var count: Int = 0
    for var address in addresses {
      var value: Float32 = 0
      var size = UInt32(MemoryLayout<Float32>.size)
      let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &value)
      if status == noErr {
        sum += Double(value)
        count += 1
      }
    }
    return count > 0 ? sum / Double(count) : 0
  }

  private func readMuted(deviceID: AudioDeviceID) -> Bool {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyMute,
      mScope: kAudioDevicePropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )
    if !AudioObjectHasProperty(deviceID, &address) {
      return false
    }
    var value: UInt32 = 0
    var size = UInt32(MemoryLayout<UInt32>.size)
    let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &value)
    if status != noErr {
      return false
    }
    return value != 0
  }
}
