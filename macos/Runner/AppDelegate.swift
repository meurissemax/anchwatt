import Cocoa
import CoreAudio
import EventKit
import FlutterMacOS
import IOKit
import IOKit.ps
import IOKit.usb

@main
class AppDelegate: FlutterAppDelegate {
  // Strong reference required: dropping it makes the NSStatusItem disappear
  // silently when the app enters background mode.
  var backgroundModeController: BackgroundModeController?
  var launchAtLoginController: LaunchAtLoginController?
  var clipboardChannel: ClipboardChannel?
  var soundPlayerChannel: SoundPlayerChannel?
  var calendarChannel: CalendarChannel?
  var calendarChangesMonitor: CalendarChangesMonitor?
  var windowStateController: WindowStateController?
  private var launchedAsLoginItem = false

  override func applicationWillFinishLaunching(_ notification: Notification) {
    super.applicationWillFinishLaunching(notification)
    // currentAppleEvent is populated by AppKit while the open-application
    // event is being processed, before the main window is ordered front.
    let event = NSAppleEventManager.shared().currentAppleEvent
    launchedAsLoginItem =
      event?.eventID == AEEventID(kAEOpenApplication) &&
      event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    if launchedAsLoginItem {
      backgroundModeController?.enterBackgroundMode()
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

final class BackgroundModeController: NSObject, NSWindowDelegate {
  // User-facing label for the right-click "quit" menu item. Hardcoded in
  // French because Anchwatt is FR-only (see lib/settings.dart). If the app
  // ever becomes multi-locale, route this through a MethodChannel from Dart.
  private static let quitMenuLabel = "Quitter Anchwatt"

  private weak var window: NSWindow?
  private var statusItem: NSStatusItem?

  // Mirrors whether the main window is currently ordered-out into the status
  // bar. Exposed via WindowStateController so Dart can gate level-up
  // notifications on "window not visible right now".
  private(set) var isHidden: Bool = false

  init(window: NSWindow) {
    self.window = window
    super.init()
    window.delegate = self
    buildStatusItem()
  }

  func enterBackgroundMode() {
    window?.orderOut(nil)
    NSApp.setActivationPolicy(.accessory)
    statusItem?.isVisible = true
    isHidden = true
  }

  func exitBackgroundMode() {
    statusItem?.isVisible = false
    NSApp.setActivationPolicy(.regular)
    // Some macOS versions leave the window behind other apps without an
    // explicit activation call after the policy switch.
    NSApp.activate(ignoringOtherApps: true)
    window?.makeKeyAndOrderFront(nil)
    isHidden = false
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    enterBackgroundMode()
    return false
  }

  private func buildStatusItem() {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let image = NSImage(named: "StatusBarIcon")
    image?.isTemplate = true
    image?.accessibilityDescription = "Anchwatt"
    item.button?.image = image
    item.button?.target = self
    item.button?.action = #selector(handleStatusItemClick(_:))
    item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
    item.isVisible = false
    self.statusItem = item
  }

  @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
    guard let event = NSApp.currentEvent else { return }
    switch event.type {
    case .rightMouseUp:
      // Temporarily attach the menu, perform the click to pop it, then detach
      // so the next left-click keeps invoking our action instead of the menu.
      let menu = NSMenu()
      let item = NSMenuItem(
        title: BackgroundModeController.quitMenuLabel,
        action: #selector(quit(_:)),
        keyEquivalent: ""
      )
      item.target = self
      menu.addItem(item)
      statusItem?.menu = menu
      sender.performClick(nil)
      statusItem?.menu = nil
    default:
      exitBackgroundMode()
    }
  }

  @objc private func quit(_ sender: Any?) {
    NSApp.terminate(nil)
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

// Tracks the volume and mute state of the internal speakers (resolved by
// InternalSpeakersResolver, with its default-output fallback) — NOT the
// system's default output device. This is the volume the XP multiplier and
// the event gating are based on.
final class SystemVolumeMonitor: NSObject, FlutterStreamHandler {
  private let resolver: InternalSpeakersResolver
  private var sink: FlutterEventSink?
  private var currentDeviceID: AudioDeviceID = AudioDeviceID(kAudioObjectUnknown)
  private var resolverToken: UUID?
  private var volumeListeners: [(AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)] = []
  private var muteListener: (AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)?
  private let listenerQueue: DispatchQueue = DispatchQueue.main

  init(resolver: InternalSpeakersResolver) {
    self.resolver = resolver
    super.init()
  }

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
    // Flutter can re-listen an EventChannel without an intervening onCancel
    // (hot restart, engine re-attach); tear the previous observer and device
    // listeners down first so they never stack.
    stop()
    currentDeviceID = resolver.deviceID
    emitCurrentState()
    resolverToken = resolver.addObserver { [weak self] in
      self?.handleResolvedDeviceChange()
    }
    if currentDeviceID != AudioDeviceID(kAudioObjectUnknown) {
      attachDeviceListeners(deviceID: currentDeviceID)
    }
  }

  private func stop() {
    if let token = resolverToken {
      resolver.removeObserver(token)
      resolverToken = nil
    }
    detachDeviceListeners(deviceID: currentDeviceID)
    currentDeviceID = AudioDeviceID(kAudioObjectUnknown)
  }

  // The volume/mute listeners are attached to a specific device — when the
  // resolver lands on a new one (jack plugged, dock, wake), they must move
  // with it, and the fresh device's state is emitted immediately.
  private func handleResolvedDeviceChange() {
    let newID = resolver.deviceID
    if newID == currentDeviceID {
      return
    }
    detachDeviceListeners(deviceID: currentDeviceID)
    currentDeviceID = newID
    if newID != AudioDeviceID(kAudioObjectUnknown) {
      attachDeviceListeners(deviceID: newID)
    }
    emitCurrentState()
  }

  // CoreAudio listener blocks fire on `listenerQueue` (main), so reads and
  // sink dispatches are guaranteed to happen on the main thread.
  private func emitCurrentState() {
    let deviceID = currentDeviceID
    // No resolvable output device: emit nothing rather than a synthetic
    // volume-0 state — Dart-side, a missing state degrades to "not gated"
    // while volume 0 would silence the app and zero its XP.
    if deviceID == AudioDeviceID(kAudioObjectUnknown) {
      return
    }
    sink?([
      "volume": readVolume(deviceID: deviceID),
      "muted": readMuted(deviceID: deviceID),
    ])
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

final class ChargerMonitor: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private var runLoopSource: CFRunLoopSource?
  // Last known providing-power-source-type value, e.g. kIOPSACPowerValue or
  // kIOPSBatteryPowerValue. Tracked so we only emit on actual transitions —
  // IOPS notifications can fire without the providing source changing.
  private var lastType: String?

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
    // Capture the initial state silently — the desktop or laptop is in some
    // power configuration when the listener boots; that is not a transition.
    lastType = currentProvidingType()

    let selfPtr = Unmanaged.passUnretained(self).toOpaque()
    guard let source = IOPSNotificationCreateRunLoopSource({ context in
      guard let context = context else { return }
      let monitor = Unmanaged<ChargerMonitor>.fromOpaque(context).takeUnretainedValue()
      monitor.handleChange()
    }, selfPtr)?.takeRetainedValue() else {
      return
    }
    self.runLoopSource = source
    CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
  }

  private func stop() {
    if let source = runLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
      runLoopSource = nil
    }
    lastType = nil
  }

  private func handleChange() {
    let newType = currentProvidingType()
    if newType == lastType {
      return
    }
    lastType = newType
    sink?(["type": newType ?? ""])
  }

  // Returns the system-wide providing power source type — typically
  // kIOPSACPowerValue ("AC Power") or kIOPSBatteryPowerValue ("Battery Power").
  // On desktop Macs without a battery, this stays "AC Power" forever.
  private func currentProvidingType() -> String? {
    guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
      return nil
    }
    return IOPSGetProvidingPowerSourceType(blob)?.takeUnretainedValue() as String?
  }
}

final class ExternalDisplayMonitor: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private var observer: NSObjectProtocol?
  // Tracked count of attached NSScreens. didChangeScreenParameters fires for
  // any screen-related change (resolution, color profile, arrangement) — we
  // only care about connect/disconnect, which manifests as a count change.
  private var lastScreenCount: Int = 0

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
    lastScreenCount = NSScreen.screens.count
    observer = NotificationCenter.default.addObserver(
      forName: NSApplication.didChangeScreenParametersNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.handleChange()
    }
  }

  private func stop() {
    if let observer = observer {
      NotificationCenter.default.removeObserver(observer)
      self.observer = nil
    }
    lastScreenCount = 0
  }

  private func handleChange() {
    let newCount = NSScreen.screens.count
    if newCount == lastScreenCount {
      return
    }
    lastScreenCount = newCount
    sink?(["count": newCount])
  }
}

final class HeadphonesMonitor: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private var currentDeviceID: AudioDeviceID = AudioDeviceID(kAudioObjectUnknown)
  private var defaultDeviceListener: AudioObjectPropertyListenerBlock?
  private var dataSourceListener: (AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)?
  private let listenerQueue: DispatchQueue = DispatchQueue.main
  // Last classification: true if the current default output looks like
  // headphones / earphones (Bluetooth audio device, or built-in headphone
  // jack). Tracked so we only emit on toggles, not on every device change.
  private var lastIsHeadphones: Bool = false

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
    lastIsHeadphones = isHeadphones(deviceID: currentDeviceID)
    attachDefaultDeviceListener()
    if currentDeviceID != AudioDeviceID(kAudioObjectUnknown) {
      attachDataSourceListener(deviceID: currentDeviceID)
    }
  }

  private func stop() {
    detachDataSourceListener(deviceID: currentDeviceID)
    detachDefaultDeviceListener()
    currentDeviceID = AudioDeviceID(kAudioObjectUnknown)
    lastIsHeadphones = false
  }

  private func evaluateAndEmit() {
    let now = isHeadphones(deviceID: currentDeviceID)
    if now == lastIsHeadphones {
      return
    }
    lastIsHeadphones = now
    sink?(["state": now ? "headphones" : "other"])
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
      self.detachDataSourceListener(deviceID: oldID)
      self.currentDeviceID = newID
      if newID != AudioDeviceID(kAudioObjectUnknown) {
        self.attachDataSourceListener(deviceID: newID)
      }
      self.evaluateAndEmit()
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

  // The built-in audio device toggles between internal speaker and headphone
  // jack via the data-source property — without the default-output device
  // changing — when the user plugs in 3.5mm headphones on a Mac that has a
  // jack. So we listen to data source changes on the current device too.
  private func attachDataSourceListener(deviceID: AudioDeviceID) {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyDataSource,
      mScope: kAudioDevicePropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )
    if !AudioObjectHasProperty(deviceID, &address) {
      return
    }
    let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
      self?.evaluateAndEmit()
    }
    let status = AudioObjectAddPropertyListenerBlock(deviceID, &address, listenerQueue, block)
    if status == noErr {
      dataSourceListener = (address, block)
    }
  }

  private func detachDataSourceListener(deviceID: AudioDeviceID) {
    if deviceID != AudioDeviceID(kAudioObjectUnknown), var entry = dataSourceListener {
      AudioObjectRemovePropertyListenerBlock(deviceID, &entry.0, listenerQueue, entry.1)
    }
    dataSourceListener = nil
  }

  // Heuristic classification:
  //   - Bluetooth* transports → headphones (vast majority of Bluetooth audio
  //     output devices in practice are headsets / earphones).
  //   - Built-in transport → read the data source: 'hdpn' is the headphone
  //     jack, 'ispk' is the internal speakers (see InternalSpeakersResolver).
  //   - All other transports (USB, AirPlay, HDMI, DisplayPort, Continuity
  //     Capture, Aggregate, Virtual, Unknown) → not headphones.
  private func isHeadphones(deviceID: AudioDeviceID) -> Bool {
    if deviceID == AudioDeviceID(kAudioObjectUnknown) {
      return false
    }
    let transport = readUInt32(deviceID: deviceID, selector: kAudioDevicePropertyTransportType)
    switch transport {
    case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE:
      return true
    case kAudioDeviceTransportTypeBuiltIn:
      let dataSource = readUInt32(deviceID: deviceID, selector: kAudioDevicePropertyDataSource)
      // 'hdpn' four-character code for headphones.
      return dataSource == 0x6864_706e
    default:
      return false
    }
  }

  private func readUInt32(deviceID: AudioDeviceID, selector: AudioObjectPropertySelector) -> UInt32? {
    var address = AudioObjectPropertyAddress(
      mSelector: selector,
      mScope: kAudioDevicePropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )
    if !AudioObjectHasProperty(deviceID, &address) {
      return nil
    }
    var value: UInt32 = 0
    var size = UInt32(MemoryLayout<UInt32>.size)
    let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &value)
    if status != noErr {
      return nil
    }
    return value
  }
}

// EventKit is not thread-safe on every API, so all calls are dispatched to the
// main queue. This handler is request/response only — see CalendarChangesMonitor
// for the EKEventStoreChanged stream that lets Dart trigger a fast re-fetch.
final class CalendarChannel: NSObject {
  // Recreatable: an EKEventStore instance can keep serving a stale authorization
  // view after the user grants access in System Settings while the app runs, so
  // Dart calls `resetStore` to force a fresh instance on (re-)authorization.
  private var eventStore = EKEventStore()

  // Activate DND this far ahead of a busy event's start so the mode is already
  // on when the event begins. Mirrors the look-back side of the predicate window.
  private static let leadTime: TimeInterval = 300

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      switch call.method {
      case "authorizationStatus":
        result(self.authorizationStatusString())
      case "requestAccess":
        self.requestAccess(result: result)
      case "currentBusyEvent":
        self.fetchCurrentBusyEvent(result: result)
      case "resetStore":
        self.eventStore = EKEventStore()
        result(nil)
      case "openSystemSettings":
        self.openSystemSettings(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func authorizationStatusString() -> String {
    let status = EKEventStore.authorizationStatus(for: .event)
    switch status {
    case .notDetermined:
      return "notDetermined"
    case .restricted:
      return "restricted"
    case .denied:
      return "denied"
    case .authorized:
      return "authorized"
    case .fullAccess:
      return "authorized"
    case .writeOnly:
      // Write-only access cannot read events — treat as denied for our purposes.
      return "denied"
    @unknown default:
      return "denied"
    }
  }

  private func requestAccess(result: @escaping FlutterResult) {
    if #available(macOS 14.0, *) {
      eventStore.requestFullAccessToEvents { granted, _ in
        DispatchQueue.main.async { result(granted) }
      }
    } else {
      eventStore.requestAccess(to: .event) { granted, _ in
        DispatchQueue.main.async { result(granted) }
      }
    }
  }

  // Look-ahead window large enough to catch an event that started slightly in
  // the past and small enough to keep the predicate cheap. We return the first
  // busy, non-all-day event that is in progress or about to start within
  // `leadTime`, so DND is already on by the time it begins.
  private func fetchCurrentBusyEvent(result: @escaping FlutterResult) {
    let now = Date()
    let predicate = eventStore.predicateForEvents(
      withStart: now.addingTimeInterval(-300),
      end: now.addingTimeInterval(3600),
      calendars: nil
    )
    let events = eventStore.events(matching: predicate)
    let match = events.first { event in
      event.availability == .busy
        && !event.isAllDay
        && event.startDate <= now.addingTimeInterval(CalendarChannel.leadTime)
        && event.endDate > now
    }
    if let match = match {
      let endMillis = Int(match.endDate.timeIntervalSince1970 * 1000)
      result([
        "id": match.eventIdentifier ?? "",
        "title": match.title ?? "",
        "endTime": endMillis,
      ])
    } else {
      result(nil)
    }
  }

  private func openSystemSettings(result: @escaping FlutterResult) {
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
      NSWorkspace.shared.open(url)
    }
    result(nil)
  }
}

final class CalendarChangesMonitor: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private let eventStore = EKEventStore()
  private var observer: NSObjectProtocol?

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    self.sink = events
    observer = NotificationCenter.default.addObserver(
      forName: .EKEventStoreChanged,
      object: eventStore,
      queue: .main
    ) { [weak self] _ in
      self?.sink?(nil)
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    if let observer = observer {
      NotificationCenter.default.removeObserver(observer)
      self.observer = nil
    }
    sink = nil
    return nil
  }
}
