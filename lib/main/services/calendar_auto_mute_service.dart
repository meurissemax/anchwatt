import 'dart:async';

import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/services/silent_mode_service.dart';
import 'package:anchwatt/main/storages/calendar_auto_mute_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CalendarAutoMuteService {
  /* Static variables */

  static const String _methodChannelName = 'com.anchwatt/calendar';
  static const String _changesChannelName = 'com.anchwatt/calendar_changes';
  static const Duration _pollInterval = Duration(seconds: 60);

  /* Variables */

  final SilentModeService _silentModeService;
  final CalendarAutoMuteStorage _storage;
  final MethodChannel _channel;
  final EventChannel _changesChannel;

  final ValueNotifier<bool> enabledNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<BusyEvent?> activeEventNotifier = ValueNotifier<BusyEvent?>(null);
  final ValueNotifier<CalendarAutoMuteError?> errorNotifier = ValueNotifier<CalendarAutoMuteError?>(null);

  // Broadcast stream of transitions caused by the real timing of a calendar
  // event (event start / event end). Transitions caused by the user — toggle
  // off mid-event, or that override expiring — are intentionally never
  // emitted, so listeners can dispatch notifications only for "natural" flips.
  final StreamController<CalendarMuteTransition> _transitionsController =
      StreamController<CalendarMuteTransition>.broadcast();

  String? _overrideEventId;
  Timer? _pollTimer;
  StreamSubscription<void>? _changesSubscription;
  bool _disposed = false;
  // Set while setEnabled() is mid-request so a resume-driven refreshPermission()
  // can't interleave with the in-flight permission prompt.
  bool _mutating = false;

  /* Constructor */

  CalendarAutoMuteService(
    this._silentModeService, {
    CalendarAutoMuteStorage? storage,
    MethodChannel? channel,
    EventChannel? changesChannel,
  }) : _storage = storage ?? CalendarAutoMuteStorage(),
       _channel = channel ?? const MethodChannel(_methodChannelName),
       _changesChannel = changesChannel ?? const EventChannel(_changesChannelName);

  /* Getters */

  bool get isEnabled => enabledNotifier.value;
  Stream<CalendarMuteTransition> get transitions => _transitionsController.stream;

  /* Methods */

  Future<void> init() async {
    await _storage.init();
    final bool persisted = _storage.readEnabled();
    if (!persisted) {
      return;
    }

    // The user authorized calendar access in a previous session but may have
    // revoked it from System Settings in the meantime — verify before kicking
    // off polling so we never silently keep a stale enabled flag.
    final bool authorized = await _isAuthorized();
    if (!authorized) {
      errorNotifier.value = CalendarAutoMuteError.permissionDenied;

      return;
    }

    enabledNotifier.value = true;
    await _startPolling();
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
        final bool granted = await _requestAccess();
        if (!granted) {
          errorNotifier.value = CalendarAutoMuteError.permissionDenied;

          return;
        }

        errorNotifier.value = null;
        enabledNotifier.value = true;
        await _storage.writeEnabled(true);
        await _startPolling();
      } else {
        enabledNotifier.value = false;
        await _storage.writeEnabled(false);
        _stopPolling();
        _overrideEventId = null;
        activeEventNotifier.value = null;
        _silentModeService.setCalendarEnabled(false);
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

    final bool authorized = await _isAuthorized();
    if (_disposed) {
      return;
    }

    if (authorized) {
      if (errorNotifier.value == CalendarAutoMuteError.permissionDenied) {
        errorNotifier.value = null;
      }

      // Restore a toggle the user had opted into but init() had to leave off
      // because the permission was missing at the time. _startPolling recreates
      // the native store so the freshly granted access is honored.
      if (_storage.readEnabled() && !enabledNotifier.value) {
        enabledNotifier.value = true;
        await _startPolling();
      }
    } else if (enabledNotifier.value) {
      // Permission revoked while enabled — mirror setEnabled(false)'s teardown.
      enabledNotifier.value = false;
      await _storage.writeEnabled(false);
      _stopPolling();
      _overrideEventId = null;
      activeEventNotifier.value = null;
      _silentModeService.setCalendarEnabled(false);
      errorNotifier.value = CalendarAutoMuteError.permissionDenied;
    }
  }

  // Called by AnchwattViewModel when the user toggles DND off while a calendar
  // event is currently driving DND on. The current event is "shadowed" until it
  // ends — we still poll, but skip the setCalendarEnabled(true) for that ID.
  void captureCurrentEventAsOverride() {
    final BusyEvent? current = activeEventNotifier.value;
    if (current == null) {
      return;
    }

    _overrideEventId = current.id;
    activeEventNotifier.value = null;
    _silentModeService.setCalendarEnabled(false);
  }

  Future<void> openSystemSettings() async {
    try {
      await _channel.invokeMethod<void>('openSystemSettings');
    } on Object catch (error) {
      debugPrint('CalendarAutoMuteService: openSystemSettings failed: $error');
    }
  }

  Future<void> _startPolling() async {
    // Recreate the native EKEventStore first: a long-lived instance can keep
    // returning stale (empty) results after a live permission re-grant even
    // though authorizationStatus already reports authorized.
    await _resetNativeStore();

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => unawaited(_tick()));

    await _changesSubscription?.cancel();
    _changesSubscription = _changesChannel.receiveBroadcastStream().listen(
      (_) => unawaited(_tick()),
      onError: (Object error) {
        debugPrint('CalendarAutoMuteService: changes channel error: $error');
      },
    );

    await _tick();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    unawaited(_changesSubscription?.cancel());
    _changesSubscription = null;
  }

  Future<void> _tick() async {
    if (_disposed || !enabledNotifier.value) {
      return;
    }

    final Object? raw;
    try {
      raw = await _channel.invokeMethod<Object?>('currentBusyEvent');
    } on Object catch (error) {
      debugPrint('CalendarAutoMuteService: currentBusyEvent failed: $error');
      errorNotifier.value = CalendarAutoMuteError.fetchFailed;

      return;
    }

    if (_disposed) {
      return;
    }

    errorNotifier.value = null;

    final BusyEvent? event = raw is Map<Object?, Object?> ? BusyEvent.fromMap(raw) : null;
    // Snapshot the state we're about to mutate so we can detect "natural"
    // transitions (event start / event end) and emit on the transitions
    // stream — override-driven changes don't move `_silentModeService.calendarEnabled`
    // here, so they never trigger an emission.
    final BusyEvent? previousActiveEvent = activeEventNotifier.value;
    final bool wasCalendarEnabled = _silentModeService.calendarEnabled;

    if (event == null) {
      // No event in flight — clear any override since the event holding it
      // either ended or got out of the look-ahead window.
      _overrideEventId = null;
      activeEventNotifier.value = null;
      _silentModeService.setCalendarEnabled(false);

      if (wasCalendarEnabled && previousActiveEvent != null) {
        _transitionsController.add(
          CalendarMuteDeactivated(endedEvent: previousActiveEvent),
        );
      }

      return;
    }

    if (event.id == _overrideEventId) {
      // Same event the user opted out of; honor the override.
      activeEventNotifier.value = null;
      _silentModeService.setCalendarEnabled(false);

      return;
    }

    // A new event started, or the previous override no longer applies.
    _overrideEventId = null;
    activeEventNotifier.value = event;
    _silentModeService.setCalendarEnabled(true);

    if (!wasCalendarEnabled) {
      _transitionsController.add(CalendarMuteActivated(event: event));
    }
  }

  Future<bool> _requestAccess() async {
    try {
      final bool? granted = await _channel.invokeMethod<bool>('requestAccess');

      return granted ?? false;
    } on Object catch (error) {
      debugPrint('CalendarAutoMuteService: requestAccess failed: $error');

      return false;
    }
  }

  Future<bool> _isAuthorized() async {
    try {
      final String? status = await _channel.invokeMethod<String>('authorizationStatus');

      return status == 'authorized';
    } on Object catch (error) {
      debugPrint('CalendarAutoMuteService: authorizationStatus failed: $error');

      return false;
    }
  }

  Future<void> _resetNativeStore() async {
    try {
      await _channel.invokeMethod<void>('resetStore');
    } on Object catch (error) {
      debugPrint('CalendarAutoMuteService: resetStore failed: $error');
    }
  }

  void dispose() {
    _disposed = true;
    _stopPolling();
    unawaited(_transitionsController.close());
    enabledNotifier.dispose();
    activeEventNotifier.dispose();
    errorNotifier.dispose();
  }
}
