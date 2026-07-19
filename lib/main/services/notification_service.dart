import 'package:anchwatt/commons/utils/number_format.dart';
import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/storages/notification_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// Thin seam over `flutter_local_notifications` so tests can plug a fake
// implementation without mocking the plugin's internal pigeon channels. The
// default implementation `_FlutterLocalNotificationsPlatform` below forwards
// to the real plugin; production code never constructs the seam directly.
@visibleForTesting
abstract class NotificationPlatform {
  Future<void> initialize({
    required void Function() onTap,
  });

  Future<bool> requestPermission();

  Future<bool> hasPermission();

  Future<void> show({
    required int id,
    required String title,
    required String body,
  });
}

class NotificationService {
  /* Static variables */

  // Stable IDs — re-using the same int makes a new notification of the same
  // kind replace the previous one in the macOS Notification Center, which is
  // the desired behaviour for back-to-back progression or DND transitions.
  static const int _idLevelUp = 1;
  static const int _idCalendarDndActivated = 2;
  static const int _idCalendarDndDeactivated = 3;
  static const int _idEvolution = 4;
  static const int _idLevelUpAndEvolution = 5;
  static const int _idHardcoreUnlocked = 6;
  static const int _idShiny = 7;

  static const String _systemSettingsUrl =
      'x-apple.systempreferences:com.apple.preference.security?Privacy_Notifications';

  /* Variables */

  final NotificationPlatform _platform;
  final NotificationStorage _storage;
  final VoidCallback? _onNotificationTap;
  // Foreground gate: when supplied, notifications are suppressed while the
  // window is in front of the user. Optional so the seam stays trivial to
  // wire in tests that don't care about this check.
  final Future<bool> Function()? _isWindowHidden;

  final ValueNotifier<bool> enabledNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<NotificationServiceError?> errorNotifier = ValueNotifier<NotificationServiceError?>(null);

  bool _disposed = false;
  // Set while setEnabled() is mid-request so a resume-driven refreshPermission()
  // can't interleave with the in-flight permission prompt.
  bool _mutating = false;

  /* Constructor */

  NotificationService({
    NotificationPlatform? platform,
    NotificationStorage? storage,
    this._isWindowHidden,
    this._onNotificationTap,
  }) : _platform = platform ?? _FlutterLocalNotificationsPlatform(),
       _storage = storage ?? NotificationStorage();

  /* Getters */

  bool get isEnabled => enabledNotifier.value;

  /* Methods */

  Future<void> init() async {
    await _storage.init();

    try {
      await _platform.initialize(onTap: _onTap);
    } on Object catch (error) {
      debugPrint('NotificationService: initialize failed: $error');
      errorNotifier.value = NotificationServiceError.initFailed;

      return;
    }

    final bool persisted = _storage.readEnabled();
    if (!persisted) {
      return;
    }

    // The user authorized notifications in a previous session but may have
    // revoked the permission from System Settings since — verify before
    // claiming the toggle is on so the UI never silently keeps a stale flag.
    final bool authorized = await _platform.hasPermission();
    if (!authorized) {
      await _storage.writeEnabled(false);
      errorNotifier.value = NotificationServiceError.permissionDenied;

      return;
    }

    enabledNotifier.value = true;
  }

  Future<void> setEnabled(bool value) async {
    if (_disposed) {
      return;
    }

    if (value == enabledNotifier.value) {
      return;
    }

    _mutating = true;

    try {
      if (value) {
        final bool granted = await _platform.requestPermission();
        if (!granted) {
          errorNotifier.value = NotificationServiceError.permissionDenied;

          return;
        }

        errorNotifier.value = null;
        enabledNotifier.value = true;
        await _storage.writeEnabled(true);
      } else {
        enabledNotifier.value = false;
        errorNotifier.value = null;
        await _storage.writeEnabled(false);
      }
    } finally {
      _mutating = false;
    }
  }

  // Re-reads the OS permission and reconciles the toggle/error state so a change
  // made in System Settings (grant or revoke) is reflected without a restart,
  // mirroring what a cold-start init() would compute for the persisted flag.
  Future<void> refreshPermission() async {
    if (_disposed || _mutating) {
      return;
    }

    final bool authorized = await _platform.hasPermission();
    if (_disposed) {
      return;
    }

    if (authorized) {
      if (errorNotifier.value == NotificationServiceError.permissionDenied) {
        errorNotifier.value = null;
      }

      // Restore a toggle the user had opted into but init() had to leave off
      // because the permission was missing at the time.
      if (_storage.readEnabled() && !enabledNotifier.value) {
        enabledNotifier.value = true;
      }
    } else if (enabledNotifier.value) {
      // Permission revoked while we still claimed on — mirror _ensureCanFire().
      enabledNotifier.value = false;
      errorNotifier.value = NotificationServiceError.permissionDenied;
      await _storage.writeEnabled(false);
    }
  }

  Future<void> openSystemSettings() async {
    try {
      await launchUrl(Uri.parse(_systemSettingsUrl));
    } on Object catch (error) {
      debugPrint('NotificationService: openSystemSettings failed: $error');
    }
  }

  Future<void> showLevelUp(int level, Evolution stage) async {
    if (!await _ensureCanFire()) {
      return;
    }

    final L10n l10n = locator<L10n>();
    await _safeShow(
      id: _idLevelUp,
      title: l10n.notificationLevelUpTitle(formatNumber(level)),
      body: l10n.notificationLevelUpBody(stage.label(l10n)),
    );
  }

  Future<void> showEvolution(Evolution oldStage, Evolution newStage) async {
    if (!await _ensureCanFire()) {
      return;
    }

    final L10n l10n = locator<L10n>();
    await _safeShow(
      id: _idEvolution,
      title: l10n.notificationEvolutionTitle,
      body: l10n.notificationEvolutionBody(oldStage.label(l10n), newStage.label(l10n)),
    );
  }

  Future<void> showLevelUpAndEvolution(int level, Evolution oldStage, Evolution newStage) async {
    if (!await _ensureCanFire()) {
      return;
    }

    final L10n l10n = locator<L10n>();
    await _safeShow(
      id: _idLevelUpAndEvolution,
      title: l10n.notificationLevelUpAndEvolutionTitle,
      body: l10n.notificationLevelUpAndEvolutionBody(oldStage.label(l10n), formatNumber(level), newStage.label(l10n)),
    );
  }

  // Fired on a shiny roll only, background-only via [_ensureCanFire]. Kept
  // independent from the progression notification so an event that both levels
  // up and rolls shiny produces two distinct notifications, not a merged one.
  Future<void> showShiny() async {
    if (!await _ensureCanFire()) {
      return;
    }

    final L10n l10n = locator<L10n>();
    await _safeShow(
      id: _idShiny,
      title: l10n.notificationShinyTitle,
      body: l10n.notificationShinyBody,
    );
  }

  Future<void> showHardcoreUnlocked() async {
    if (!await _ensureCanFire()) {
      return;
    }

    final L10n l10n = locator<L10n>();
    await _safeShow(
      id: _idHardcoreUnlocked,
      title: l10n.notificationHardcoreUnlockedTitle,
      body: l10n.notificationHardcoreUnlockedBody,
    );
  }

  Future<void> showCalendarDndActivated(String eventTitle, DateTime endTime) async {
    if (!await _ensureCanFire()) {
      return;
    }

    final L10n l10n = locator<L10n>();
    final String resolvedTitle = eventTitle.isEmpty ? l10n.notificationCalendarEventFallbackName : eventTitle;
    await _safeShow(
      id: _idCalendarDndActivated,
      title: l10n.notificationDndActivatedTitle,
      body: l10n.notificationDndActivatedBody(resolvedTitle, DateFormat.Hm().format(endTime)),
    );
  }

  Future<void> showCalendarDndDeactivated(String eventTitle) async {
    if (!await _ensureCanFire()) {
      return;
    }

    final L10n l10n = locator<L10n>();
    final String resolvedTitle = eventTitle.isEmpty ? l10n.notificationCalendarEventFallbackName : eventTitle;
    await _safeShow(
      id: _idCalendarDndDeactivated,
      title: l10n.notificationDndDeactivatedTitle,
      body: l10n.notificationDndDeactivatedBody(resolvedTitle),
    );
  }

  // Returns true iff the service is currently authorized to fire. If the
  // permission was revoked from System Settings while the master flag stayed
  // on, force the flag off and surface the error so the UI keeps in sync.
  // Also enforces the foreground gate: when the window is in front of the
  // user, the notification is dropped silently.
  Future<bool> _ensureCanFire() async {
    if (_disposed || !enabledNotifier.value) {
      return false;
    }

    final bool authorized = await _platform.hasPermission();
    if (!authorized) {
      enabledNotifier.value = false;
      errorNotifier.value = NotificationServiceError.permissionDenied;
      await _storage.writeEnabled(false);

      return false;
    }

    final Future<bool> Function()? isWindowHidden = _isWindowHidden;
    if (isWindowHidden != null) {
      final bool hidden = await isWindowHidden();
      if (!hidden) {
        return false;
      }
    }

    return true;
  }

  Future<void> _safeShow({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _platform.show(id: id, title: title, body: body);
    } on Object catch (error) {
      debugPrint('NotificationService: show(id=$id) failed: $error');
    }
  }

  void _onTap() {
    _onNotificationTap?.call();
  }

  void dispose() {
    _disposed = true;
    enabledNotifier.dispose();
    errorNotifier.dispose();
  }
}

class _FlutterLocalNotificationsPlatform implements NotificationPlatform {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize({
    required void Function() onTap,
  }) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        macOS: DarwinInitializationSettings(
          // Permission prompts are routed through the service so the user sees
          // them only when they opt in, not at every cold start.
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (_) => onTap(),
    );
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final bool? granted = await _plugin
          .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            sound: true,
          );

      return granted ?? false;
    } on Object catch (error) {
      debugPrint('NotificationService: requestPermissions failed: $error');

      return false;
    }
  }

  @override
  Future<bool> hasPermission() async {
    try {
      final NotificationsEnabledOptions? options = await _plugin
          .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();

      // Alert is the minimum we need to display the notification body to the
      // user — sound is nice-to-have but not blocking.
      return options?.isAlertEnabled ?? false;
    } on Object catch (error) {
      debugPrint('NotificationService: checkPermissions failed: $error');

      return false;
    }
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) {
    return _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        macOS: DarwinNotificationDetails(),
      ),
    );
  }
}
