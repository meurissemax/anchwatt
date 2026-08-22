// Generates lib/main/sound_durations.dart: a const map of every sound asset's
// nominal duration in milliseconds, keyed by the asset key used at the
// `AssetSource` call site (the full repo-relative path, e.g.
// 'assets/sounds/friday/plop.m4a').
//
// Run from the repo root: `dart run tools/generate_sound_durations.dart`.
// Re-run after adding or removing a sound asset. Requires macOS (`afinfo`).

import 'dart:io';

const String _soundsDir = 'assets/sounds';
const String _outputPath = 'lib/main/sound_durations.dart';

const Set<String> _audioExtensions = {'.mp3', '.wav', '.m4a', '.aiff'};

final RegExp _durationPattern = RegExp('estimated duration: ([0-9.]+)');

Never _fail(String message) {
  stderr.writeln('Error: $message');
  exit(1);
}

int _readDurationMs(String path) {
  final ProcessResult result;

  try {
    result = Process.runSync('afinfo', [path]);
  } on ProcessException {
    _fail('afinfo is not available — this script requires macOS.');
  }

  if (result.exitCode != 0) {
    _fail('afinfo failed for $path:\n${result.stderr}');
  }

  final Match? match = _durationPattern.firstMatch(result.stdout as String);

  if (match == null) {
    _fail('could not parse an estimated duration for $path.');
  }

  final double? seconds = double.tryParse(match.group(1)!);

  if (seconds == null || seconds <= 0) {
    _fail('invalid estimated duration "${match.group(1)}" for $path.');
  }

  return (seconds * 1000).round();
}

void main() {
  final Directory soundsDir = Directory(_soundsDir);

  if (!soundsDir.existsSync()) {
    _fail('$_soundsDir not found — run this script from the repo root.');
  }

  final List<String> assets = soundsDir
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path)
      .where((path) => _audioExtensions.any(path.endsWith))
      .toList()
    ..sort();

  if (assets.isEmpty) {
    _fail('no audio asset found under $_soundsDir.');
  }

  final StringBuffer buffer = StringBuffer()
    ..writeln('// GENERATED FILE — DO NOT EDIT MANUALLY.')
    ..writeln(
      '// Run `dart run tools/generate_sound_durations.dart` after adding or removing a sound asset.',
    )
    ..writeln()
    ..writeln('/// Nominal duration, in milliseconds, of every sound asset, keyed by the')
    ..writeln('/// asset key used at the `AssetSource` call site (the full repo-relative')
    ..writeln('/// path, e.g. `assets/sounds/friday/plop.m4a`).')
    ..writeln('const Map<String, int> soundDurationsMs = <String, int>{');

  for (final String asset in assets) {
    buffer.writeln("  '$asset': ${_readDurationMs(asset)},");
  }

  buffer.writeln('};');

  File(_outputPath).writeAsStringSync(buffer.toString());
  stdout.writeln('Wrote ${assets.length} entries to $_outputPath.');
}
