import 'package:anchwatt/main/services/silent_mode_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('SilentModeService defaults to disabled when no value is stored', () async {
    final SilentModeService service = SilentModeService();
    await service.init();

    expect(service.isEnabled, false);
    expect(service.manualEnabled, false);
    expect(service.calendarEnabled, false);
  });

  test('SilentModeService setManualEnabled flips the manual flag and persists across instances', () async {
    final SilentModeService first = SilentModeService();
    await first.init();

    expect(first.isEnabled, false);

    await first.setManualEnabled(true);
    expect(first.isEnabled, true);
    expect(first.manualEnabled, true);

    final SilentModeService second = SilentModeService();
    await second.init();

    expect(second.isEnabled, true);
    expect(second.manualEnabled, true);

    await second.setManualEnabled(false);
    expect(second.isEnabled, false);

    final SilentModeService third = SilentModeService();
    await third.init();

    expect(third.isEnabled, false);
  });

  test('SilentModeService setManualEnabled only notifies on OR transitions', () async {
    final SilentModeService service = SilentModeService();
    await service.init();

    int notifications = 0;
    service.enabledNotifier.addListener(() => notifications++);

    await service.setManualEnabled(false);
    expect(notifications, 0);

    await service.setManualEnabled(true);
    expect(notifications, 1);

    await service.setManualEnabled(true);
    expect(notifications, 1);
  });

  test('SilentModeService combines manual and calendar flags via OR', () async {
    final SilentModeService service = SilentModeService();
    await service.init();

    expect(service.isEnabled, false);

    service.setCalendarEnabled(true);
    expect(service.isEnabled, true);
    expect(service.calendarEnabled, true);
    expect(service.manualEnabled, false);

    await service.setManualEnabled(true);
    expect(service.isEnabled, true);

    service.setCalendarEnabled(false);
    expect(service.isEnabled, true); // manual still true

    await service.setManualEnabled(false);
    expect(service.isEnabled, false);
  });

  test('SilentModeService calendar flag is not persisted', () async {
    final SilentModeService first = SilentModeService();
    await first.init();

    first.setCalendarEnabled(true);
    expect(first.isEnabled, true);

    final SilentModeService second = SilentModeService();
    await second.init();

    expect(second.calendarEnabled, false);
    expect(second.isEnabled, false);
  });

  test('SilentModeService enabledNotifier does not fire when only one source flips inside the OR', () async {
    final SilentModeService service = SilentModeService();
    await service.init();

    await service.setManualEnabled(true);

    int notifications = 0;
    service.enabledNotifier.addListener(() => notifications++);

    // OR stays true while calendar flips.
    service.setCalendarEnabled(true);
    expect(notifications, 0);

    service.setCalendarEnabled(false);
    expect(notifications, 0);

    await service.setManualEnabled(false);
    expect(notifications, 1);
  });
}
