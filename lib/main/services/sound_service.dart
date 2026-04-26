import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SoundService {
  /* Static variables */

  static const String _soundsPrefix = 'assets/sounds/';
  static const Set<String> _supportedExtensions = {'.mp3', '.wav'};

  /* Variables */

  final AudioCache _cache = AudioCache(prefix: '');
  final Set<AudioPlayer> _activePlayers = {};
  final Random _random = Random();

  List<String> _assetPaths = [];

  /* Methods */

  Future<void> init() async {
    final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    _assetPaths = manifest
        .listAssets()
        .where(
          (key) => key.startsWith(_soundsPrefix) && _supportedExtensions.any(key.endsWith),
        )
        .toList();

    if (_assetPaths.isEmpty) {
      debugPrint('SoundService: no sound assets found under $_soundsPrefix');

      return;
    }

    await _cache.loadAll(_assetPaths);
  }

  void playRandom() {
    if (_assetPaths.isEmpty) {
      return;
    }

    final String asset = _assetPaths[_random.nextInt(_assetPaths.length)];
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

  Future<void> dispose() async {
    final List<AudioPlayer> players = _activePlayers.toList();
    _activePlayers.clear();

    for (final AudioPlayer player in players) {
      await player.stop();
      await player.dispose();
    }
  }
}
