import 'dart:async';
import 'dart:math';

import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/storages/sound_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SoundService {
  /* Static variables */

  static const String _soundsPrefix = 'assets/sounds/';
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

    final List<String> toPreload = _assetsByMode.values.expand((paths) => paths).toList();

    if (toPreload.isEmpty) {
      debugPrint('SoundService: no sound assets found under $_soundsPrefix');

      return;
    }

    await _cache.loadAll(toPreload);
  }

  void playRandom() {
    final List<String> pool = _assetsByMode[modeNotifier.value] ?? const [];

    if (pool.isEmpty) {
      debugPrint('SoundService: no sounds available for mode ${modeNotifier.value.name}');

      return;
    }

    final String asset = pool[_random.nextInt(pool.length)];
    final AudioPlayer player = AudioPlayer();

    // Bind the player to our prefix-less cache so AssetSource resolves to the
    // exact key we preloaded with. The default global cache prepends 'assets/'.
    player.audioCache = _cache;
    _activePlayers.add(player);

    late final StreamSubscription<void> sub;

    sub = player.onPlayerComplete.listen(
      (_) async {
        _activePlayers.remove(player);
        await sub.cancel();
        await player.dispose();
      },
    );

    player
        .play(AssetSource(asset))
        .catchError(
          (Object error) => debugPrint('SoundService play error: $error'),
        );
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
