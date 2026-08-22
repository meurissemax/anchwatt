import AVFoundation
import FlutterMacOS
import Foundation

// Plays the app's bundled sound assets through the internal speakers resolved
// by InternalSpeakersResolver, leaving the system default output untouched:
// the user's music keeps playing in their headphones while Anchwatt stays
// audible in the room. Playback + resource lifecycle only — which sound plays,
// and whether it may play at all, is decided Dart-side.
final class SoundPlayerChannel: NSObject {
  // Release cached assets and pooled players after this long without any
  // playback, so an app that idles in the status bar all day does not keep
  // the audio hardware engaged. The first sound after an idle stretch pays a
  // small warm-up cost, by design.
  private static let idleReleaseInterval: TimeInterval = 180

  // Players kept warm for reuse between closely-spaced sounds. Overlapping
  // playbacks beyond the pool size allocate extra players, dropped again on
  // completion.
  private static let maxPooledPlayers = 3

  // One in-flight playback: the player/item pair, the pending FlutterResult
  // (answered exactly once, when playback ends, fails or is stopped) and the
  // observations that must be torn down with it.
  private final class Playback {
    let player: AVPlayer
    let item: AVPlayerItem
    let result: FlutterResult
    var endObserver: NSObjectProtocol?
    var failObserver: NSObjectProtocol?
    var statusObservation: NSKeyValueObservation?

    init(player: AVPlayer, item: AVPlayerItem, result: @escaping FlutterResult) {
      self.player = player
      self.item = item
      self.result = result
    }
  }

  private let resolver: InternalSpeakersResolver
  private var resolverToken: UUID?
  private var assetsByKey: [String: AVURLAsset] = [:]
  private var activePlaybacks: [UUID: Playback] = [:]
  private var pooledPlayers: [AVPlayer] = []
  private var idleTimer: Timer?

  init(resolver: InternalSpeakersResolver) {
    self.resolver = resolver
    super.init()
    resolverToken = resolver.addObserver { [weak self] in
      self?.rerouteAllPlayers()
    }
  }

  deinit {
    if let token = resolverToken {
      resolver.removeObserver(token)
    }
    idleTimer?.invalidate()
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "play":
      guard
        let arguments = call.arguments as? [String: Any],
        let asset = arguments["asset"] as? String
      else {
        result(FlutterError(code: "bad_arguments", message: "play expects an 'asset' string", details: nil))
        return
      }
      play(assetKey: asset, result: result)
    case "stopAll":
      stopAll()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // Routes a fresh player to the internal speakers and starts playback. The
  // FlutterResult is only answered once playback finishes — the Dart caller
  // awaits the full sound, and the XP volume-sampling window depends on that.
  private func play(assetKey: String, result: @escaping FlutterResult) {
    guard let asset = loadAsset(forKey: assetKey) else {
      result(FlutterError(code: "asset_not_found", message: "No bundled sound asset at \(assetKey)", details: nil))
      return
    }

    cancelIdleTimer()

    let item = AVPlayerItem(asset: asset)
    let player = dequeuePlayer()
    // Route this player only — nil (resolver fallback) leaves the system
    // default routing in place.
    player.audioOutputDeviceUniqueID = resolver.routingUID

    let playbackID = UUID()
    let playback = Playback(player: player, item: item, result: result)
    activePlaybacks[playbackID] = playback

    playback.endObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: item,
      queue: .main
    ) { [weak self] _ in
      self?.finish(playbackID: playbackID, error: nil)
    }
    playback.failObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemFailedToPlayToEndTime,
      object: item,
      queue: .main
    ) { [weak self] _ in
      self?.finish(playbackID: playbackID, error: "Playback failed for \(assetKey)")
    }
    // A load failure (unreadable or corrupt file) surfaces on the item status
    // without either notification above ever firing. KVO can fire off-main.
    playback.statusObservation = item.observe(\.status) { [weak self] observedItem, _ in
      if observedItem.status == .failed {
        DispatchQueue.main.async {
          self?.finish(playbackID: playbackID, error: "Could not load \(assetKey)")
        }
      }
    }

    player.replaceCurrentItem(with: item)
    player.play()
  }

  // Stops every in-flight playback and answers its pending result, so Dart
  // futures awaiting play never hang when DND flips on mid-sound.
  private func stopAll() {
    for playbackID in Array(activePlaybacks.keys) {
      finish(playbackID: playbackID, error: nil)
    }
  }

  // Tears one playback down and answers its result exactly once (re-entry is
  // a no-op thanks to the removeValue guard, e.g. a failure notification
  // racing the status KVO).
  private func finish(playbackID: UUID, error: String?) {
    guard let playback = activePlaybacks.removeValue(forKey: playbackID) else {
      return
    }

    if let endObserver = playback.endObserver {
      NotificationCenter.default.removeObserver(endObserver)
    }
    if let failObserver = playback.failObserver {
      NotificationCenter.default.removeObserver(failObserver)
    }
    playback.statusObservation?.invalidate()

    playback.player.pause()
    playback.player.replaceCurrentItem(with: nil)
    if pooledPlayers.count < SoundPlayerChannel.maxPooledPlayers {
      pooledPlayers.append(playback.player)
    }

    if let error = error {
      playback.result(FlutterError(code: "playback_error", message: error, details: nil))
    } else {
      playback.result(nil)
    }

    if activePlaybacks.isEmpty {
      armIdleTimer()
    }
  }

  private func dequeuePlayer() -> AVPlayer {
    if let player = pooledPlayers.popLast() {
      return player
    }
    return AVPlayer()
  }

  // Parsed assets are cached on first use (not preloaded at launch) and
  // dropped by the idle release, so replays within a burst stay cheap.
  private func loadAsset(forKey key: String) -> AVURLAsset? {
    if let cached = assetsByKey[key] {
      return cached
    }
    guard
      let url = SoundPlayerChannel.flutterAssetURL(forKey: key),
      FileManager.default.fileExists(atPath: url.path)
    else {
      return nil
    }
    let asset = AVURLAsset(url: url)
    assetsByKey[key] = asset
    return asset
  }

  // Flutter bundles its assets inside the embedded App framework:
  //   <app>/Contents/Frameworks/App.framework/Resources/flutter_assets/<key>
  private static func flutterAssetURL(forKey key: String) -> URL? {
    guard let frameworksPath = Bundle.main.privateFrameworksPath else {
      return nil
    }
    let appFrameworkPath = (frameworksPath as NSString).appendingPathComponent("App.framework")
    guard let resourceURL = Bundle(path: appFrameworkPath)?.resourceURL else {
      return nil
    }
    return resourceURL
      .appendingPathComponent("flutter_assets")
      .appendingPathComponent(key)
  }

  private func armIdleTimer() {
    idleTimer?.invalidate()
    idleTimer = Timer.scheduledTimer(
      withTimeInterval: SoundPlayerChannel.idleReleaseInterval,
      repeats: false
    ) { [weak self] _ in
      self?.releaseIdleResources()
    }
  }

  private func cancelIdleTimer() {
    idleTimer?.invalidate()
    idleTimer = nil
  }

  private func releaseIdleResources() {
    idleTimer = nil
    pooledPlayers.removeAll()
    assetsByKey.removeAll()
  }

  // AVPlayer routing is per-player state: when the resolver lands on another
  // device (or falls back), in-flight and pooled players must both follow.
  private func rerouteAllPlayers() {
    let uid = resolver.routingUID
    for playback in activePlaybacks.values {
      playback.player.audioOutputDeviceUniqueID = uid
    }
    for player in pooledPlayers {
      player.audioOutputDeviceUniqueID = uid
    }
  }
}
