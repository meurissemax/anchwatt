import 'package:anchwatt/l10n/outputs/l10n.dart';

/// Formats a duration given in milliseconds as a human-readable string:
/// "Xh Ymin" from one hour up, "Ymin Zs" below. Negative values clamp to 0.
String formatSoundDuration(L10n l10n, int durationMs) {
  final Duration duration = Duration(milliseconds: durationMs < 0 ? 0 : durationMs);

  if (duration.inHours >= 1) {
    return l10n.durationHoursMinutes(duration.inHours, duration.inMinutes.remainder(60));
  }

  return l10n.durationMinutesSeconds(duration.inMinutes, duration.inSeconds.remainder(60));
}
