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

    await service.showLevelUp(7, Evolution.anchwatt);
    await service.showEvolution(Evolution.anchwatt, Evolution.lamperoie);
    await service.showLevelUpAndEvolution(15, Evolution.anchwatt, Evolution.lamperoie);
    await service.showHardcoreUnlocked();
    await service.showCalendarDndActivated('Daily standup', DateTime(2026, 5, 17, 14, 30));
    await service.showCalendarDndDeactivated('Daily standup');

    expect(platform.shown, isEmpty);

    service.dispose();
  });

  test('showLevelUp embeds the level in the title and the stage label in the body', () async {
    final NotificationService service = NotificationService(platform: platform);
    await service.init();
    await service.setEnabled(true);

    await service.showLevelUp(7, Evolution.anchwatt);
    await service.showLevelUp(20, Evolution.lamperoie);

    expect(platform.shown.length, 2);
    expect(platform.shown.every((s) => s.id == 1), true);
    expect(platform.shown.first.title, contains('7'));
    expect(platform.shown.first.body, contains('Anchwatt'));
    expect(platform.shown.last.title, contains('20'));
    expect(platform.shown.last.body, contains('Lampéroie'));

    service.dispose();
  });

  test('showEvolution names both stages and uses a distinct stable id', () async {
    final NotificationService service = NotificationService(platform: platform);
    await service.init();
    await service.setEnabled(true);

    await service.showEvolution(Evolution.anchwatt, Evolution.lamperoie);

    expect(platform.shown.length, 1);
    expect(platform.shown.single.id, 4);
    expect(platform.shown.single.body, contains('Anchwatt'));
    expect(platform.shown.single.body, contains('Lampéroie'));
    expect(
      platform.shown.single.body.indexOf('Anchwatt'),
      lessThan(platform.shown.single.body.indexOf('Lampéroie')),
    );

    service.dispose();
  });

  test('showLevelUpAndEvolution embeds level, old stage then new stage', () async {
    final NotificationService service = NotificationService(platform: platform);
    await service.init();
    await service.setEnabled(true);

    await service.showLevelUpAndEvolution(15, Evolution.anchwatt, Evolution.lamperoie);

    expect(platform.shown.length, 1);
    expect(platform.shown.single.id, 5);
    expect(platform.shown.single.body, contains('15'));
    expect(platform.shown.single.body, contains('Anchwatt'));
    expect(platform.shown.single.body, contains('Lampéroie'));
    expect(
      platform.shown.single.body.indexOf('Anchwatt'),
      lessThan(platform.shown.single.body.indexOf('Lampéroie')),
    );

    service.dispose();
  });

  test('showHardcoreUnlocked fires once with a distinct stable id and non-empty copy', () async {
    final NotificationService service = NotificationService(platform: platform);
    await service.init();
    await service.setEnabled(true);

    await service.showHardcoreUnlocked();

    expect(platform.shown.length, 1);
    expect(platform.shown.single.id, 6);
    expect(platform.shown.single.title, isNotEmpty);
    expect(platform.shown.single.body, isNotEmpty);

    service.dispose();
  });

  test('showAchievementsUnlocked coalesces several badges into one notification', () async {
    final NotificationService service = NotificationService(platform: platform);
    await service.init();
    await service.setEnabled(true);

    await service.showAchievementsUnlocked(<Achievement>[Achievement.firstSpark, Achievement.chromatic]);

    final L10n l10n = locator<L10n>();
    expect(platform.shown.length, 1);
    expect(platform.shown.single.id, 8);
    expect(platform.shown.single.title, l10n.notificationAchievementsUnlockedTitle(2));
    expect(platform.shown.single.body, contains(Achievement.firstSpark.label(l10n)));
    expect(platform.shown.single.body, contains(Achievement.chromatic.label(l10n)));

    service.dispose();
  });

  test('showAchievementsUnlocked uses the singular title and the badge label as body for one badge', () async {
    final NotificationService service = NotificationService(platform: platform);
    await service.init();
    await service.setEnabled(true);

    await service.showAchievementsUnlocked(<Achievement>[Achievement.endOfLine]);

    final L10n l10n = locator<L10n>();
    expect(platform.shown.length, 1);
    expect(platform.shown.single.id, 8);
    expect(platform.shown.single.title, l10n.notificationAchievementUnlockedTitle);
    expect(platform.shown.single.body, l10n.achievementEndOfLineLabel);

    service.dispose();
  });

  test('showAchievementsUnlocked fires nothing for an empty list', () async {
    final NotificationService service = NotificationService(platform: platform);
    await service.init();
    await service.setEnabled(true);

    await service.showAchievementsUnlocked(const <Achievement>[]);

    expect(platform.shown, isEmpty);

    service.dispose();
  });

  test('showAchievementsUnlocked is suppressed while the window is visible', () async {
    final NotificationService service = NotificationService(
      platform: platform,
      isWindowHidden: () async => false,
    );
    await service.init();
    await service.setEnabled(true);

    await service.showAchievementsUnlocked(<Achievement>[Achievement.firstSpark]);

    expect(platform.shown, isEmpty);

    service.dispose();
  });

  test('showCalendarDndActivated puts the event title before the end time', () async {
    final NotificationService service = NotificationService(platform: platform);
    await service.init();
    await service.setEnabled(true);

    await service.showCalendarDndActivated('Daily standup', DateTime(2026, 5, 17, 14, 30));

    expect(platform.shown.length, 1);
    expect(platform.shown.single.id, 2);
    expect(platform.shown.single.body, contains('Daily standup'));
    expect(platform.shown.single.body, contains('14:30'));
    // Regression guard: the previous build emitted "14:30 ... Daily standup"
    // because the ARB placeholders were sorted alphabetically while the call
    // site passed (title, time).
    expect(
      platform.shown.single.body.indexOf('Daily standup'),
      lessThan(platform.shown.single.body.indexOf('14:30')),
    );

    service.dispose();
  });

  test('showCalendarDndDeactivated keeps a distinct stable id and embeds the event title', () async {
    final NotificationService service = NotificationService(platform: platform);
    await service.init();
    await service.setEnabled(true);

    await service.showCalendarDndDeactivated('Daily standup');

    expect(platform.shown.length, 1);
    expect(platform.shown.single.id, 3);
    expect(platform.shown.single.body, contains('Daily standup'));

    service.dispose();
  });

  test('DND notifications use a fallback label when the calendar event title is empty', () async {
    final NotificationService service = NotificationService(platform: platform);
    await service.init();
    await service.setEnabled(true);

    await service.showCalendarDndActivated('', DateTime(2026, 5, 17, 14, 30));
    await service.showCalendarDndDeactivated('');

    expect(platform.shown.length, 2);
    expect(platform.shown[0].body, contains('un événement'));
    expect(platform.shown[1].body, contains('un événement'));

    service.dispose();
  });

  test('foreground gate suppresses every notification when the window is visible', () async {
    bool windowHidden = false;
    final NotificationService service = NotificationService(
      platform: platform,
      isWindowHidden: () async => windowHidden,
    );
    await service.init();
    await service.setEnabled(true);

    await service.showLevelUp(7, Evolution.anchwatt);
    await service.showEvolution(Evolution.anchwatt, Evolution.lamperoie);
    await service.showLevelUpAndEvolution(15, Evolution.anchwatt, Evolution.lamperoie);
    await service.showCalendarDndActivated('Standup', DateTime(2026, 5, 17, 14, 30));
    await service.showCalendarDndDeactivated('Standup');

    expect(platform.shown, isEmpty, reason: 'no notification should fire while the window is visible');

    windowHidden = true;
    await service.showLevelUp(7, Evolution.anchwatt);

    expect(platform.shown.length, 1);

    service.dispose();
  });

  test('runtime permission revocation forces the master flag off and surfaces the error', () async {
    final NotificationService service = NotificationService(platform: platform);
    await service.init();
    await service.setEnabled(true);
    expect(service.isEnabled, true);

    // Permission was revoked from System Settings between dispatches.
    platform.hasPermissionResult = false;

    await service.showLevelUp(7, Evolution.anchwatt);

    expect(service.isEnabled, false);
    expect(service.errorNotifier.value, NotificationServiceError.permissionDenied);
    expect(platform.shown, isEmpty);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notifications.enabled'), false);

    service.dispose();
  });

  test('refreshPermission clears a stale permissionDenied error once granted, without enabling', () async {
    platform.grantPermission = false;
    platform.hasPermissionResult = false;

    final NotificationService service = NotificationService(platform: platform);
    await service.init();
    await service.setEnabled(true);
    expect(service.isEnabled, false);
    expect(service.errorNotifier.value, NotificationServiceError.permissionDenied);

    // User grants the permission in System Settings, then refocuses the app.
    platform.hasPermissionResult = true;
    await service.refreshPermission();

    expect(service.isEnabled, false);
    expect(service.errorNotifier.value, isNull);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notifications.enabled'), isNot(true));

    service.dispose();
  });

  test('refreshPermission keeps a refused-but-off toggle untouched while the permission stays denied', () async {
    platform.grantPermission = false;
    platform.hasPermissionResult = false;

    final NotificationService service = NotificationService(platform: platform);
    await service.init();
    await service.setEnabled(true);
    expect(service.errorNotifier.value, NotificationServiceError.permissionDenied);

    await service.refreshPermission();

    expect(service.isEnabled, false);
    expect(service.errorNotifier.value, NotificationServiceError.permissionDenied);

    service.dispose();
  });

  test('refreshPermission forces the toggle off and surfaces an error when the permission was revoked', () async {
    final NotificationService service = NotificationService(platform: platform);
    await service.init();
    await service.setEnabled(true);
    expect(service.isEnabled, true);

    // Permission revoked from System Settings while the app ran.
    platform.hasPermissionResult = false;
    await service.refreshPermission();

    expect(service.isEnabled, false);
    expect(service.errorNotifier.value, NotificationServiceError.permissionDenied);

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
