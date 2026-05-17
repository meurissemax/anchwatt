import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/storages/sound_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SoundService {
  /* Static variables */

  static const String _soundsPrefix = 'assets/sounds/';
  static const String _criesPrefix = 'assets/sounds/cries/';
  static const Set<String> _supportedExtensions = {'.mp3', '.m4a'};

  /* Variables */

  final AudioCache _cache = AudioCache(prefix: '');
  final Set<AudioPlayer> _activePlayers = {};
  final Random _random = Random();
  final SoundStorage _storage = SoundStorage();
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
          (key) => key.startsWith(_soundsPrefix) && _supportedExtensions.any(key.endsWith),
        )
        .toList();

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

    final List<String> toPreload = [
      ..._assetsByMode.values.expand((paths) => paths),
      ..._criesByEvolution.values,
    ];

    if (toPreload.isEmpty) {
      debugPrint('SoundService: no sound assets found under $_soundsPrefix');

      return;
    }

    await _cache.loadAll(toPreload);
  }

  Future<void> playRandom() {
    final SoundMode mode = modeNotifier.value;
    final List<String> pool = _assetsByMode[mode] ?? const [];

    if (pool.isEmpty) {
      debugPrint('SoundService: no sounds available for mode ${mode.name}');

      return Future<void>.value();
    }

    // Rolling-window exclusion: never repeat one of the last [effectiveK]
    // picks for this mode. Clamped so a pool of 1 or 2 always has at least
    // 2 eligible candidates (i.e. exclusion is skipped entirely below 3).
    final Queue<String> recent = _recentByMode[mode]!;
    final int effectiveK = pool.length <= 2
        ? 0
        : min(AnchwattSettings.randomSoundExclusionWindow, pool.length - 2);

    final List<String> eligible = effectiveK > 0
        ? pool.where((asset) => !recent.contains(asset)).toList()
        : pool;

    final String asset = eligible[_random.nextInt(eligible.length)];

    if (effectiveK > 0) {
      recent.addLast(asset);
      while (recent.length > effectiveK) {
        recent.removeFirst();
      }
    }

    return _playAsset(asset, errorLabel: 'SoundService play error');
  }

  Future<void> playCry(Evolution evolution) {
    final String? asset = _criesByEvolution[evolution];

    if (asset == null) {
      debugPrint('SoundService: no cry asset found for evolution ${evolution.name}');

      return Future<void>.value();
    }

    return _playAsset(asset, errorLabel: 'SoundService cry play error');
  }

  Future<void> _playAsset(String asset, {required String errorLabel}) {
    final AudioPlayer player = AudioPlayer();

    // Bind the player to our prefix-less cache so AssetSource resolves to the
    // exact key we preloaded with. The default global cache prepends 'assets/'.
    player.audioCache = _cache;
    _activePlayers.add(player);

    final Completer<void> completer = Completer<void>();
    late final StreamSubscription<void> sub;

    Future<void> finish() async {
      if (completer.isCompleted) {
        return;
      }
      completer.complete();
      _activePlayers.remove(player);
      await sub.cancel();
      await player.dispose();
    }

    sub = player.onPlayerComplete.listen((_) => finish());

    player.play(AssetSource(asset)).catchError((Object error) {
      debugPrint('$errorLabel: $error');
      finish();
    });

    return completer.future;
  }

  Future<void> toggleMode() async {
    final SoundMode next = modeNotifier.value.next;
    modeNotifier.value = next;
    await _storage.writeMode(next);
  }

  Future<void> dispose() async {
    final List<AudioPlayer> players = _activePlayers.toList();
    _activePlayers.clear();

    for (final AudioPlayer player in players) {
      await player.stop();
      await player.dispose();
    }

    modeNotifier.dispose();
  }
}
