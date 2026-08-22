import 'dart:collection';
import 'dart:math';

import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/services/stats_service.dart';
import 'package:anchwatt/main/storages/sound_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SoundService {
  /* Static variables */

  static const String _channelName = 'com.anchwatt/sound_player';
  static const String _soundsPrefix = 'assets/sounds/';
  static const String _criesPrefix = 'assets/sounds/cries/';
  static const String _supportedExtension = '.m4a';

  /* Variables */

  // Native AVPlayer bridge, routed to the internal speakers so Anchwatt stays
  // audible in the room whatever output the user listens to. The native side
  // resolves asset keys straight from the app bundle and caches them on first
  // use — no Dart-side preloading.
  final MethodChannel _channel = const MethodChannel(_channelName);
  final Random _random = Random();
  final SoundStorage _storage = SoundStorage();
  final StatsService _statsService = locator<StatsService>();
  final ValueNotifier<SoundMode> modeNotifier = ValueNotifier<SoundMode>(SoundMode.corporate);

  final Map<SoundMode, List<String>> _assetsByMode = {
    for (final SoundMode mode in SoundMode.values) mode: <String>[],
  };
  final Map<SoundMode, Queue<String>> _recentByMode = {
    for (final SoundMode mode in SoundMode.values) mode: ListQueue<String>(),
  };
  final Map<Evolution, String> _criesByEvolution = {};

  /* Getters */

  SoundMode get mode => modeNotifier.value;

  /* Methods */

  Future<void> init() async {
    await _storage.init();
    modeNotifier.value = _storage.readMode();

    final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final List<String> all = manifest
        .listAssets()
        .where(
          (key) => key.startsWith(_soundsPrefix) && key.endsWith(_supportedExtension),
        )
        .toList();

    if (all.isEmpty) {
      debugPrint('SoundService: no sound assets found under $_soundsPrefix');
    }

    for (final SoundMode mode in SoundMode.values) {
      final String prefix = '$_soundsPrefix${mode.assetSubfolder}';
      _assetsByMode[mode] = all.where((key) => key.startsWith(prefix)).toList();
    }

    for (final String key in all.where((path) => path.startsWith(_criesPrefix))) {
      for (final Evolution evolution in Evolution.values) {
        final String fileName = key.substring(_criesPrefix.length);
        if (fileName.startsWith('${evolution.name}.')) {
          _criesByEvolution[evolution] = key;
          break;
        }
      }
    }
  }

  // Resolves to the played asset key once playback completes (null when the
  // mode's pool is empty or playback failed), so the caller can look up the
  // sound's nominal duration in the generated manifest.
  Future<String?> playRandom() async {
    final SoundMode mode = modeNotifier.value;
    final List<String> pool = _assetsByMode[mode] ?? const [];

    if (pool.isEmpty) {
      debugPrint('SoundService: no sounds available for mode ${mode.name}');

      return null;
    }

    // Rolling-window exclusion: never repeat one of the last [effectiveK]
    // picks for this mode. Clamped so a pool of 1 or 2 always has at least
    // 2 eligible candidates (i.e. exclusion is skipped entirely below 3).
    final Queue<String> recent = _recentByMode[mode]!;
    final int effectiveK = pool.length <= 2 ? 0 : min(AnchwattSettings.randomSoundExclusionWindow, pool.length - 2);

    final List<String> eligible = effectiveK > 0 ? pool.where((asset) => !recent.contains(asset)).toList() : pool;

    final String asset = eligible[_random.nextInt(eligible.length)];

    if (effectiveK > 0) {
      recent.addLast(asset);
      while (recent.length > effectiveK) {
        recent.removeFirst();
      }
    }

    final bool played = await _playAsset(asset, errorLabel: 'SoundService play error');

    if (!played) {
      return null;
    }

    // Every mode feeds its own "Sons lâchés" counter, hardcore included. DND
    // and silenced speakers are gated upstream, and a failed playback returns
    // above, so only sounds actually heard count. Pet cries (playCry) are an
    // independent caress sound and intentionally skip this.
    _statsService.recordSoundPlayed(mode);

    return asset;
  }

  // Resolves to the played cry's asset key once playback completes (null when
  // no cry asset exists for the evolution or playback failed), mirroring
  // [playRandom].
  Future<String?> playCry(Evolution evolution) async {
    final String? asset = _criesByEvolution[evolution];

    if (asset == null) {
      debugPrint('SoundService: no cry asset found for evolution ${evolution.name}');

      return null;
    }

    final bool played = await _playAsset(asset, errorLabel: 'SoundService cry play error');

    return played ? asset : null;
  }

  // Invokes the native player, which only answers once the sound finished,
  // failed or was stopped — so awaiting this spans the whole playback (the
  // XP volume-sampling window depends on it). Returns false on failure, so
  // callers can skip the duration-based stats and XP for a sound nobody
  // heard; a stopAll interruption answers as a success and still counts.
  // Errors are logged, never rethrown: a failed sound must not break the
  // event pipeline.
  Future<bool> _playAsset(String asset, {required String errorLabel}) async {
    try {
      await _channel.invokeMethod<void>('play', {'asset': asset});

      return true;
    } on Object catch (error) {
      debugPrint('$errorLabel: $error');

      return false;
    }
  }

  Future<void> setMode(SoundMode mode) async {
    if (modeNotifier.value == mode) {
      return;
    }

    modeNotifier.value = mode;
    await _storage.writeMode(mode);
  }

  // Stops every in-flight playback; the native side answers each pending
  // play call, so the futures returned by [playRandom] / [playCry] resolve
  // and awaiting callers don't hang when the user flips Do Not Disturb on
  // mid-sound.
  Future<void> stopAll() async {
    try {
      await _channel.invokeMethod<void>('stopAll');
    } on Object catch (error) {
      debugPrint('SoundService stopAll error: $error');
    }
  }

  Future<void> dispose() async {
    await stopAll();
    modeNotifier.dispose();
  }
}
