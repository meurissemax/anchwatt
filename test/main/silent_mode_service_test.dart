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
  });

  test('SilentModeService toggle flips state and persists across instances', () async {
    final SilentModeService first = SilentModeService();
    await first.init();

    expect(first.isEnabled, false);

    await first.toggle();
    expect(first.isEnabled, true);

    final SilentModeService second = SilentModeService();
    await second.init();

    expect(second.isEnabled, true);

    await second.toggle();
    expect(second.isEnabled, false);

    final SilentModeService third = SilentModeService();
    await third.init();

    expect(third.isEnabled, false);
  });

  test('SilentModeService setEnabled is a no-op when the value is unchanged', () async {
    final SilentModeService service = SilentModeService();
    await service.init();

    int notifications = 0;
    service.enabledNotifier.addListener(() => notifications++);

    await service.setEnabled(false);
    expect(notifications, 0);

    await service.setEnabled(true);
    expect(notifications, 1);

    await service.setEnabled(true);
    expect(notifications, 1);
  });
}
