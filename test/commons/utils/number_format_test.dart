import 'package:anchwatt/commons/utils/number_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  // formatNumber relies on the ambient Intl.defaultLocale, which L10n.load()
  // sets to 'fr' in the running app. Pin it here so the test is deterministic
  // regardless of the host machine's locale.
  setUpAll(() {
    Intl.defaultLocale = 'fr';
  });

  // French groups thousands with a narrow no-break space (U+202F), built from
  // its code point so the expectations never rely on an invisible glyph.
  final String sep = String.fromCharCode(0x202f);

  group('formatNumber', () {
    test('groups thousands with a narrow no-break space', () {
      expect(formatNumber(12564), '12${sep}564');
    });

    test('groups every three digits for large numbers', () {
      expect(formatNumber(1000000), '1${sep}000${sep}000');
    });

    test('leaves numbers below 1000 ungrouped', () {
      expect(formatNumber(999), '999');
    });

    test('formats zero as "0"', () {
      expect(formatNumber(0), '0');
    });
  });
}
