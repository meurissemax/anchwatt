import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/services/stats_service.dart';
import 'package:anchwatt/main/view_models/anchwatt_view_model.dart';
import 'package:anchwatt/main/view_models/stats_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    setupLocator();
  });

  // Kept synchronous on purpose: the parent's async boot (which would re-init
  // the shared StatsService) cannot interleave without an await, so the counts
  // recorded here are exactly what the ViewModel reads back.
  test('favorite event and réveils total exclude pet and fall back when empty', () {
    final L10n l10n = locator<L10n>();
    final AnchwattViewModel parent = AnchwattViewModel();
    final StatsService stats = locator<StatsService>();

    // No system event yet → empty-state fallback, zero réveils.
    final StatsViewModel empty = StatsViewModel(parent);
    expect(empty.totalWakeups, 0);
    expect(empty.favoriteEventLabel, l10n.statsFavoriteEventEmpty);

    // The pet must never count toward réveils nor win the favorite, even when
    // it is by far the most frequent record; usbToggle is the busiest real
    // system event and should win.
    stats.recordSystemEvent(AnchwattEventType.pet);
    stats.recordSystemEvent(AnchwattEventType.pet);
    stats.recordSystemEvent(AnchwattEventType.pet);
    stats.recordSystemEvent(AnchwattEventType.chargerToggle);
    stats.recordSystemEvent(AnchwattEventType.usbToggle);
    stats.recordSystemEvent(AnchwattEventType.usbToggle);

    final StatsViewModel populated = StatsViewModel(parent);
    expect(populated.totalWakeups, 3);
    expect(populated.favoriteEventLabel, l10n.eventTypeUsbToggle);
  });
}
