import 'package:intl/intl.dart';

// Cached so the locale symbols are parsed once. Lazily initialized on first
// call, which always happens after L10n.load() has set Intl.defaultLocale to
// 'fr' (same pattern as the cached DateFormat in StatsViewModel).
final NumberFormat _decimalFormat = NumberFormat.decimalPattern();

/// Formats [value] with locale-aware thousands grouping.
///
/// French groups with a narrow no-break space, e.g. 12564 -> "12 564".
String formatNumber(int value) => _decimalFormat.format(value);
