import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNotificationPlatform implements NotificationPlatform {
  bool initialized = false;
  bool grantPermission = true;
  bool hasPermissionResult = true;
  bool throwOnInitialize = false;
  void Function()? onTapCallback;

  final List<_Shown> shown = <_Shown>[];
  int permissionRequests = 0;
  int permissionChecks = 0;

  @override
  Future<void> initialize({
    required void Function() onTap,
  }) async {
    if (throwOnInitialize) {
      throw Exception('initialize failed');
    }

    initialized = true;
    onTapCallback = onTap;
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequests += 1;
    if (grantPermission) {
      hasPermissionResult = true;
    }

    return grantPermission;
  }

  @override
  Future<bool> hasPermission() async {
    permissionChecks += 1;

    return hasPermissionResult;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    shown.add(_Shown(id: id, title: title, body: body));
  }
}

class _Shown {
  final int id;
  final String title;
  final String body;

  const _Shown({
    required this.id,
    required this.title,
    required this.body,
  });
}

void main() {
  late _FakeNotificationPlatform platform;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    if (!locator.isRegistered<L10n>()) {
      locator.registerSingleton<L10n>(L10n());
    }
    platform = _FakeNotificationPlatform();
  });

  test('init does nothing when no flag was persisted', () async {
    final NotificationService service = NotificationService(platform: platform);

    await service.init();

    expect(platform.initialized, true);
    expect(service.isEnabled, false);
    expect(service.errorNotifier.value, isNull);
    expect(platform.permissionChecks, 0);

    service.dispose();
  });

  test('init recovers cleanly when the persisted flag survives but the permission was revoked', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'notifications.enabled': true});
    platform.hasPermissionResult = false;

    final NotificationService service = NotificationService(platform: platform);
    await service.init();

    expect(service.isEnabled, false);
    expect(service.errorNotifier.value, NotificationServiceError.permissionDenied);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notifications.enabled'), false);

    service.dispose();
  });

  test('init keeps the toggle on when the persisted flag is true and the permission is still granted', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'notifications.enabled': true});
    platform.hasPermissionResult = true;

    final NotificationService service = NotificationService(platform: platform);
    await service.init();

    expect(service.isEnabled, true);
    expect(service.errorNotifier.value, isNull);

    service.dispose();
  });

  test('setEnabled(true) requests permission, persists, and clears any prior error', () async {
    final NotificationService service = NotificationService(platform: platform);
    await service.init();

    service.errorNotifier.value = NotificationServiceError.permissionDenied;

    await service.setEnabled(true);

    expect(service.isEnabled, true);
    expect(service.errorNotifier.value, isNull);
    expect(platform.permissionRequests, 1);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notifications.enabled'), true);

    service.dispose();
  });

  test('setEnabled(true) keeps the toggle off and surfaces an error when the permission is refused', () async {
    platform.grantPermission = false;
    platform.hasPermissionResult = false;

    final NotificationService service = NotificationService(platform: platform);
    await service.init();
    await service.setEnabled(true);

    expect(service.isEnabled, false);
    expect(service.errorNotifier.value, NotificationServiceError.permissionDenied);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notifications.enabled'), isNot(true));

    service.dispose();
  });

  test('setEnabled(false) clears the persisted flag and any error', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'notifications.enabled': true});

    final NotificationService service = NotificationService(platform: platform);
    await service.init();
    expect(service.isEnabled, true);

    await service.setEnabled(false);

    expect(service.isEnabled, false);
    expect(service.errorNotifier.value, isNull);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notifications.enabled'), false);

    service.dispose();
  });

  test('show methods are no-ops when the master flag is off', () async {
    final NotificationService service = NotificationService(platform: platform);
    await service.init();

    await service.showLevelUp(Evolution.lamperoie);
    await service.showCalendarDndActivated('Daily standup', DateTime(2026, 5, 17, 14, 30));
    await service.showCalendarDndDeactivated('Daily standup');

    expect(platform.shown, isEmpty);

    service.dispose();
  });

  test('showLevelUp fires once enabled and uses a stable id', () async {
    final NotificationService service = NotificationService(platform: platform);
    await service.init();
    await service.setEnabled(true);

    await service.showLevelUp(Evolution.lamperoie);
    await service.showLevelUp(Evolution.ohmassacre);

    expect(platform.shown.length, 2);
    expect(platform.shown.every((s) => s.id == 1), true);
    expect(platform.shown.last.body, contains('Ohmassacre'));

    service.dispose();
  });

  test('showCalendarDndActivated and Deactivated use distinct stable ids and embed the event', () async {
    final NotificationService service = NotificationService(platform: platform);
    await service.init();
    await service.setEnabled(true);

    await service.showCalendarDndActivated('Daily standup', DateTime(2026, 5, 17, 14, 30));
    await service.showCalendarDndDeactivated('Daily standup');

    expect(platform.shown.length, 2);
    expect(platform.shown[0].id, 2);
    expect(platform.shown[0].body, contains('Daily standup'));
    expect(platform.shown[0].body, contains('14:30'));
    expect(platform.shown[1].id, 3);
    expect(platform.shown[1].body, contains('Daily standup'));

    service.dispose();
  });

  test('runtime permission revocation forces the master flag off and surfaces the error', () async {
    final NotificationService service = NotificationService(platform: platform);
    await service.init();
    await service.setEnabled(true);
    expect(service.isEnabled, true);

    // Permission was revoked from System Settings between dispatches.
    platform.hasPermissionResult = false;

    await service.showLevelUp(Evolution.lamperoie);

    expect(service.isEnabled, false);
    expect(service.errorNotifier.value, NotificationServiceError.permissionDenied);
    expect(platform.shown, isEmpty);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notifications.enabled'), false);

    service.dispose();
  });

  test('the tap callback is forwarded when the platform invokes it', () async {
    int taps = 0;
    final NotificationService service = NotificationService(
      platform: platform,
      onNotificationTap: () => taps += 1,
    );
    await service.init();

    expect(platform.onTapCallback, isNotNull);
    platform.onTapCallback!();
    platform.onTapCallback!();

    expect(taps, 2);

    service.dispose();
  });

  test('init failure surfaces an initFailed error', () async {
    platform.throwOnInitialize = true;

    final NotificationService service = NotificationService(platform: platform);
    await service.init();

    expect(service.errorNotifier.value, NotificationServiceError.initFailed);
    expect(service.isEnabled, false);

    service.dispose();
  });
}
