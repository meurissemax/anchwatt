import 'dart:io';

import 'package:anchwatt/main/sound_durations.dart';
import 'package:flutter_test/flutter_test.dart';

// Guard against a forgotten regeneration: the generated duration manifest must
// stay in exact sync with the audio assets on disk. Fails when an asset has no
// entry (run `dart run tools/generate_sound_durations.dart`) and when an
// orphan entry survives a deleted asset.
void main() {
  const Set<String> audioExtensions = {'.mp3', '.wav', '.m4a', '.aiff'};

  Set<String> listAudioAssets() => Directory('assets/sounds')
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path)
      .where((path) => audioExtensions.any(path.endsWith))
      .toSet();

  test('every audio asset has a duration entry and no orphan entry remains', () {
    final Set<String> assets = listAudioAssets();

    expect(assets, isNotEmpty);
    expect(
      assets.difference(soundDurationsMs.keys.toSet()),
      isEmpty,
      reason: 'missing manifest entries — run `dart run tools/generate_sound_durations.dart`',
    );
    expect(
      soundDurationsMs.keys.toSet().difference(assets),
      isEmpty,
      reason: 'orphan manifest entries — run `dart run tools/generate_sound_durations.dart`',
    );
  });

  test('every duration entry is strictly positive', () {
    for (final MapEntry<String, int> entry in soundDurationsMs.entries) {
      expect(entry.value, greaterThan(0), reason: entry.key);
    }
  });
}
