import CoreAudio
import Foundation

/// Resolves the output device backing the Mac's internal speakers,
/// independently of the system's default output device, and re-resolves when
/// the audio topology or the default output changes (jack plug/unplug, dock,
/// external display, wake from sleep).
///
/// Consumers (the system-volume monitor and the native sound player) read
/// `deviceID` / `routingUID` and can register an observer to be notified on
/// the main queue whenever the resolution changes.
///
/// Known limitation on Intel Macs: the built-in device is a single device
/// whose data source flips between internal speakers and the headphone jack
/// without any topology change, so plugging a jack neither re-resolves the
/// device nor re-routes private playback away from the jack. Documented
/// behaviour, not worked around.
final class InternalSpeakersResolver {
  // Output data-source code of the built-in device. Apple does not document
  // these FourCC values, but they are stable in practice across macOS
  // releases ('ispk' internal speakers, 'hdpn' headphone jack, 'espk'
  // external speakers). If a future macOS stops reporting 'ispk', resolution
  // fails and the resolver falls back to the default output device.
  private static let dataSourceInternalSpeakers: UInt32 = 0x6973_706B  // 'ispk'

  // CoreAudio listener blocks and Flutter channel handlers all run on the
  // main queue, so every read/write of the mutable state below is serialized.
  private let listenerQueue: DispatchQueue = DispatchQueue.main

  /// The resolved internal-speakers device, or the default output device when
  /// resolution failed (see `routingUID` for how to tell the two apart).
  private(set) var deviceID: AudioDeviceID = AudioDeviceID(kAudioObjectUnknown)

  /// UID to route private playback to: the internal speakers' UID, or nil
  /// when resolution fell back to the default output device (a player left
  /// untouched then follows the system default routing).
  private(set) var routingUID: String?

  private var observers: [UUID: () -> Void] = [:]
  private var systemListeners: [(AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)] = []
  private var didLogFallback = false

  func start() {
    resolve()
    // Both selectors funnel into the same re-resolution: the devices list for
    // topology changes (jack creating an "External Headphones" device on
    // Apple Silicon, docks, wake), the default output so a fallback keeps
    // tracking the device the user actually hears.
    attachSystemListener(selector: kAudioHardwarePropertyDevices)
    attachSystemListener(selector: kAudioHardwarePropertyDefaultOutputDevice)
  }

  func stop() {
    for (var address, block) in systemListeners {
      AudioObjectRemovePropertyListenerBlock(
        AudioObjectID(kAudioObjectSystemObject),
        &address,
        listenerQueue,
        block
      )
    }
    systemListeners.removeAll()
  }

  /// Registers a block invoked on the main queue after every resolution
  /// change. Returns a token for `removeObserver`.
  func addObserver(_ block: @escaping () -> Void) -> UUID {
    let token = UUID()
    observers[token] = block
    return token
  }

  func removeObserver(_ token: UUID) {
    observers.removeValue(forKey: token)
  }

  private func attachSystemListener(selector: AudioObjectPropertySelector) {
    var address = AudioObjectPropertyAddress(
      mSelector: selector,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
      self?.handleAudioConfigurationChange()
    }
    let status = AudioObjectAddPropertyListenerBlock(
      AudioObjectID(kAudioObjectSystemObject),
      &address,
      listenerQueue,
      block
    )
    if status == noErr {
      systemListeners.append((address, block))
    }
  }

  private func handleAudioConfigurationChange() {
    let oldDeviceID = deviceID
    let oldRoutingUID = routingUID
    resolve()
    if deviceID == oldDeviceID && routingUID == oldRoutingUID {
      return
    }
    for observer in observers.values {
      observer()
    }
  }

  private func resolve() {
    if let resolved = findInternalSpeakersDevice() {
      deviceID = resolved
      routingUID = readDeviceUID(deviceID: resolved)
      // Re-arm the one-shot fallback log so a future loss of the device is
      // reported once per episode, not once per app run.
      didLogFallback = false
      return
    }

    if !didLogFallback {
      NSLog("InternalSpeakersResolver: no internal speakers found, falling back to the default output device")
      didLogFallback = true
    }
    deviceID = resolveDefaultOutputDevice()
    routingUID = nil
  }

  // A device qualifies as the internal speakers when it has output channels,
  // its transport is built-in AND its current output data source is 'ispk'.
  // The data-source check is what tells the internal speakers apart from the
  // separate "External Headphones" device a plugged-in jack creates on Apple
  // Silicon — that one is also BuiltIn, but reports 'hdpn'.
  private func findInternalSpeakersDevice() -> AudioDeviceID? {
    for candidate in allDevices() {
      guard hasOutputChannels(deviceID: candidate) else { continue }

      let transport = readUInt32(
        objectID: candidate,
        selector: kAudioDevicePropertyTransportType,
        scope: kAudioObjectPropertyScopeGlobal
      )
      guard transport == kAudioDeviceTransportTypeBuiltIn else { continue }

      let dataSource = readUInt32(
        objectID: candidate,
        selector: kAudioDevicePropertyDataSource,
        scope: kAudioDevicePropertyScopeOutput
      )
      guard dataSource == InternalSpeakersResolver.dataSourceInternalSpeakers else { continue }

      return candidate
    }
    return nil
  }

  private func allDevices() -> [AudioDeviceID] {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDevices,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var size: UInt32 = 0
    var status = AudioObjectGetPropertyDataSize(
      AudioObjectID(kAudioObjectSystemObject),
      &address,
      0,
      nil,
      &size
    )
    guard status == noErr, size > 0 else {
      return []
    }
    var devices = [AudioDeviceID](
      repeating: AudioDeviceID(kAudioObjectUnknown),
      count: Int(size) / MemoryLayout<AudioDeviceID>.size
    )
    status = AudioObjectGetPropertyData(
      AudioObjectID(kAudioObjectSystemObject),
      &address,
      0,
      nil,
      &size,
      &devices
    )
    guard status == noErr else {
      return []
    }
    return devices
  }

  private func hasOutputChannels(deviceID: AudioDeviceID) -> Bool {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyStreamConfiguration,
      mScope: kAudioDevicePropertyScopeOutput,
      mElement: kAudioObjectPropertyElementMain
    )
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size) == noErr, size > 0 else {
      return false
    }
    let raw = UnsafeMutableRawPointer.allocate(
      byteCount: Int(size),
      alignment: MemoryLayout<AudioBufferList>.alignment
    )
    defer { raw.deallocate() }
    let bufferList = raw.assumingMemoryBound(to: AudioBufferList.self)
    guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, bufferList) == noErr else {
      return false
    }
    return bufferList.pointee.mNumberBuffers > 0
  }

  private func resolveDefaultOutputDevice() -> AudioDeviceID {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDefaultOutputDevice,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    var defaultDeviceID = AudioDeviceID(kAudioObjectUnknown)
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)
    let status = AudioObjectGetPropertyData(
      AudioObjectID(kAudioObjectSystemObject),
      &address,
      0,
      nil,
      &size,
      &defaultDeviceID
    )
    return status == noErr ? defaultDeviceID : AudioDeviceID(kAudioObjectUnknown)
  }

  private func readDeviceUID(deviceID: AudioDeviceID) -> String? {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioDevicePropertyDeviceUID,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )
    guard AudioObjectHasProperty(deviceID, &address) else {
      return nil
    }
    // The property hands back a retained CFString — takeRetainedValue
    // balances that +1 so the string is neither leaked nor over-released.
    var unmanagedUID: Unmanaged<CFString>?
    var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &unmanagedUID)
    guard status == noErr, let unmanagedUID = unmanagedUID else {
      return nil
    }
    return unmanagedUID.takeRetainedValue() as String
  }

  private func readUInt32(
    objectID: AudioDeviceID,
    selector: AudioObjectPropertySelector,
    scope: AudioObjectPropertyScope
  ) -> UInt32? {
    var address = AudioObjectPropertyAddress(
      mSelector: selector,
      mScope: scope,
      mElement: kAudioObjectPropertyElementMain
    )
    guard AudioObjectHasProperty(objectID, &address) else {
      return nil
    }
    var value: UInt32 = 0
    var size = UInt32(MemoryLayout<UInt32>.size)
    let status = AudioObjectGetPropertyData(objectID, &address, 0, nil, &size, &value)
    guard status == noErr else {
      return nil
    }
    return value
  }
}
