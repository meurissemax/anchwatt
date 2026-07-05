import 'dart:async';

import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/services/calendar_auto_mute_service.dart';
import 'package:anchwatt/main/services/silent_mode_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeStreamHandler extends MockStreamHandler {
  MockStreamHandlerEventSink? sink;

  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {
    sink = events;
  }

  @override
  void onCancel(Object? arguments) {
    sink = null;
  }
}

void main() {
  const MethodChannel methodChannel = MethodChannel('com.anchwatt/calendar');
  const EventChannel changesChannel = EventChannel('com.anchwatt/calendar_changes');

  late List<MethodCall> calls;
  late String authStatus;
  late bool grantAccess;
  late Map<Object?, Object?>? currentEvent;
  late _FakeStreamHandler streamHandler;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    calls = <MethodCall>[];
    authStatus = 'notDetermined';
    grantAccess = true;
    currentEvent = null;
    streamHandler = _FakeStreamHandler();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      methodChannel,
      (MethodCall call) async {
        calls.add(call);

        switch (call.method) {
          case 'authorizationStatus':
            return authStatus;
          case 'requestAccess':
            if (grantAccess) {
              authStatus = 'authorized';
            }

            return grantAccess;
          case 'currentBusyEvent':
            return currentEvent;
          case 'openSystemSettings':
            return null;
          default:
            return null;
        }
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
      changesChannel,
      streamHandler,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      methodChannel,
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
      changesChannel,
      null,
    );
  });

  Future<SilentModeService> buildSilentMode() async {
    final SilentModeService silent = SilentModeService();
    await silent.init();

    return silent;
  }

  test('setEnabled(true) requests access, persists, and triggers a first tick', () async {
    final SilentModeService silent = await buildSilentMode();
    final CalendarAutoMuteService service = CalendarAutoMuteService(silent);

    await service.init();

    expect(service.isEnabled, false);
    expect(calls, isEmpty);

    await service.setEnabled(true);

    expect(service.isEnabled, true);
    expect(service.errorNotifier.value, isNull);
    expect(
      calls.map((c) => c.method).toList(),
      containsAllInOrder(<String>['requestAccess', 'currentBusyEvent']),
    );

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('calendar_auto_mute.enabled'), true);

    service.dispose();
  });

  test('refused access keeps the service disabled and surfaces an error', () async {
    grantAccess = false;
    final SilentModeService silent = await buildSilentMode();
    final CalendarAutoMuteService service = CalendarAutoMuteService(silent);

    await service.init();
    await service.setEnabled(true);

    expect(service.isEnabled, false);
    expect(service.errorNotifier.value, CalendarAutoMuteError.permissionDenied);
    expect(silent.isEnabled, false);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('calendar_auto_mute.enabled'), isNot(true));

    service.dispose();
  });

  test('a busy event flips calendarEnabled to true and populates activeEvent', () async {
    final SilentModeService silent = await buildSilentMode();
    final CalendarAutoMuteService service = CalendarAutoMuteService(silent);
    await service.init();

    final DateTime endTime = DateTime.now().add(const Duration(minutes: 30));
    currentEvent = <Object?, Object?>{
      'id': 'event-1',
      'title': 'Daily standup',
      'endTime': endTime.millisecondsSinceEpoch,
    };

    await service.setEnabled(true);

    expect(silent.isEnabled, true);
    expect(silent.calendarEnabled, true);
    expect(service.activeEventNotifier.value?.id, 'event-1');
    expect(service.activeEventNotifier.value?.title, 'Daily standup');

    service.dispose();
  });

  test('clearing the current event flips calendarEnabled back to false', () async {
    final SilentModeService silent = await buildSilentMode();
    final CalendarAutoMuteService service = CalendarAutoMuteService(silent);
    await service.init();

    currentEvent = <Object?, Object?>{
      'id': 'event-1',
      'title': 'Daily standup',
      'endTime': DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch,
    };
    await service.setEnabled(true);
    expect(silent.calendarEnabled, true);

    // Simulate the meeting ending: native bridge says no event in flight, the
    // change observer fires and the service re-fetches.
    currentEvent = null;
    streamHandler.sink?.success(null);
    await Future<void>.delayed(Duration.zero);

    expect(silent.calendarEnabled, false);
    expect(service.activeEventNotifier.value, isNull);

    service.dispose();
  });

  test('captureCurrentEventAsOverride keeps DND off for the rest of the event', () async {
    final SilentModeService silent = await buildSilentMode();
    final CalendarAutoMuteService service = CalendarAutoMuteService(silent);
    await service.init();

    currentEvent = <Object?, Object?>{
      'id': 'event-1',
      'title': 'Daily standup',
      'endTime': DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch,
    };
    await service.setEnabled(true);
    expect(silent.calendarEnabled, true);

    service.captureCurrentEventAsOverride();
    expect(silent.calendarEnabled, false);
    expect(service.activeEventNotifier.value, isNull);

    // A native change still says the same event is in flight: the override
    // must hold.
    streamHandler.sink?.success(null);
    await Future<void>.delayed(Duration.zero);

    expect(silent.calendarEnabled, false);
    expect(service.activeEventNotifier.value, isNull);

    // Now the event ends — override is forgotten — and a new event begins.
    currentEvent = <Object?, Object?>{
      'id': 'event-2',
      'title': 'Sync',
      'endTime': DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch,
    };
    streamHandler.sink?.success(null);
    await Future<void>.delayed(Duration.zero);

    expect(silent.calendarEnabled, true);
    expect(service.activeEventNotifier.value?.id, 'event-2');

    service.dispose();
  });

  test('a fetch error sets the fetchFailed error without clearing the previous state', () async {
    final SilentModeService silent = await buildSilentMode();
    final CalendarAutoMuteService service = CalendarAutoMuteService(silent);
    await service.init();

    currentEvent = <Object?, Object?>{
      'id': 'event-1',
      'title': 'Daily standup',
      'endTime': DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch,
    };
    await service.setEnabled(true);
    expect(silent.calendarEnabled, true);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      methodChannel,
      (MethodCall call) async {
        if (call.method == 'currentBusyEvent') {
          throw PlatformException(code: 'fetch_failed');
        }

        return null;
      },
    );

    streamHandler.sink?.success(null);
    await Future<void>.delayed(Duration.zero);

    expect(service.errorNotifier.value, CalendarAutoMuteError.fetchFailed);
    // Previous state is preserved.
    expect(silent.calendarEnabled, true);
    expect(service.activeEventNotifier.value?.id, 'event-1');

    service.dispose();
  });

  test('init recovers cleanly when access was revoked between sessions', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'calendar_auto_mute.enabled': true});
    authStatus = 'denied';

    final SilentModeService silent = await buildSilentMode();
    final CalendarAutoMuteService service = CalendarAutoMuteService(silent);

    await service.init();

    expect(service.isEnabled, false);
    expect(service.errorNotifier.value, CalendarAutoMuteError.permissionDenied);
    expect(silent.calendarEnabled, false);
    expect(calls.where((c) => c.method == 'currentBusyEvent'), isEmpty);

    service.dispose();
  });

  test('refreshPermission clears a stale permissionDenied error once access is granted, without enabling', () async {
    grantAccess = false;
    final SilentModeService silent = await buildSilentMode();
    final CalendarAutoMuteService service = CalendarAutoMuteService(silent);

    await service.init();
    await service.setEnabled(true);
    expect(service.isEnabled, false);
    expect(service.errorNotifier.value, CalendarAutoMuteError.permissionDenied);

    // User grants access in System Settings, then refocuses the app.
    authStatus = 'authorized';
    await service.refreshPermission();

    expect(service.isEnabled, false);
    expect(service.errorNotifier.value, isNull);
    expect(calls.where((c) => c.method == 'currentBusyEvent'), isEmpty);

    service.dispose();
  });

  test('refreshPermission tears down and surfaces an error when access was revoked while enabled', () async {
    final SilentModeService silent = await buildSilentMode();
    final CalendarAutoMuteService service = CalendarAutoMuteService(silent);
    await service.init();

    currentEvent = <Object?, Object?>{
      'id': 'event-1',
      'title': 'Daily standup',
      'endTime': DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch,
    };
    await service.setEnabled(true);
    expect(service.isEnabled, true);
    expect(silent.calendarEnabled, true);

    // Access revoked from System Settings while the app ran.
    authStatus = 'denied';
    await service.refreshPermission();

    expect(service.isEnabled, false);
    expect(service.errorNotifier.value, CalendarAutoMuteError.permissionDenied);
    expect(silent.calendarEnabled, false);
    expect(service.activeEventNotifier.value, isNull);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('calendar_auto_mute.enabled'), false);

    service.dispose();
  });

  test('refreshPermission restores a persisted toggle and recreates the native store on re-grant', () async {
    // Access was granted in a previous session (flag persisted) then revoked in
    // System Settings before this launch: init leaves the toggle off with an error.
    SharedPreferences.setMockInitialValues(<String, Object>{'calendar_auto_mute.enabled': true});
    authStatus = 'denied';

    final SilentModeService silent = await buildSilentMode();
    final CalendarAutoMuteService service = CalendarAutoMuteService(silent);
    await service.init();
    expect(service.isEnabled, false);
    expect(service.errorNotifier.value, CalendarAutoMuteError.permissionDenied);

    // User re-grants access in System Settings, then refocuses the app.
    authStatus = 'authorized';
    calls.clear();
    await service.refreshPermission();

    expect(service.isEnabled, true);
    expect(service.errorNotifier.value, isNull);
    // The native store is recreated before polling resumes so the fresh grant
    // is honored, then the first tick fetches the current event.
    expect(
      calls.map((c) => c.method).toList(),
      containsAllInOrder(<String>['resetStore', 'currentBusyEvent']),
    );

    service.dispose();
  });

  test('a natural activation emits CalendarMuteActivated with the event', () async {
    final SilentModeService silent = await buildSilentMode();
    final CalendarAutoMuteService service = CalendarAutoMuteService(silent);
    await service.init();

    final List<CalendarMuteTransition> transitions = <CalendarMuteTransition>[];
    final StreamSubscription<CalendarMuteTransition> sub = service.transitions.listen(transitions.add);

    final DateTime endTime = DateTime.now().add(const Duration(minutes: 30));
    currentEvent = <Object?, Object?>{
      'id': 'event-1',
      'title': 'Daily standup',
      'endTime': endTime.millisecondsSinceEpoch,
    };

    await service.setEnabled(true);
    await Future<void>.delayed(Duration.zero);

    expect(transitions.length, 1);
    expect(transitions.single, isA<CalendarMuteActivated>());
    expect((transitions.single as CalendarMuteActivated).event.id, 'event-1');
    expect((transitions.single as CalendarMuteActivated).event.title, 'Daily standup');

    await sub.cancel();
    service.dispose();
  });

  test('a natural deactivation emits CalendarMuteDeactivated with the ended event', () async {
    final SilentModeService silent = await buildSilentMode();
    final CalendarAutoMuteService service = CalendarAutoMuteService(silent);
    await service.init();

    final List<CalendarMuteTransition> transitions = <CalendarMuteTransition>[];
    final StreamSubscription<CalendarMuteTransition> sub = service.transitions.listen(transitions.add);

    currentEvent = <Object?, Object?>{
      'id': 'event-1',
      'title': 'Daily standup',
      'endTime': DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch,
    };
    await service.setEnabled(true);
    await Future<void>.delayed(Duration.zero);

    transitions.clear();

    // Meeting ends.
    currentEvent = null;
    streamHandler.sink?.success(null);
    await Future<void>.delayed(Duration.zero);

    expect(transitions.length, 1);
    expect(transitions.single, isA<CalendarMuteDeactivated>());
    expect((transitions.single as CalendarMuteDeactivated).endedEvent.id, 'event-1');

    await sub.cancel();
    service.dispose();
  });

  test('a user override (toggle DND off mid-event) emits no transition', () async {
    final SilentModeService silent = await buildSilentMode();
    final CalendarAutoMuteService service = CalendarAutoMuteService(silent);
    await service.init();

    currentEvent = <Object?, Object?>{
      'id': 'event-1',
      'title': 'Daily standup',
      'endTime': DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch,
    };
    await service.setEnabled(true);
    await Future<void>.delayed(Duration.zero);

    final List<CalendarMuteTransition> transitions = <CalendarMuteTransition>[];
    final StreamSubscription<CalendarMuteTransition> sub = service.transitions.listen(transitions.add);

    service.captureCurrentEventAsOverride();
    await Future<void>.delayed(Duration.zero);

    expect(transitions, isEmpty);

    await sub.cancel();
    service.dispose();
  });

  test('override expiration (overridden event ends with no new event) emits no transition', () async {
    final SilentModeService silent = await buildSilentMode();
    final CalendarAutoMuteService service = CalendarAutoMuteService(silent);
    await service.init();

    currentEvent = <Object?, Object?>{
      'id': 'event-1',
      'title': 'Daily standup',
      'endTime': DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch,
    };
    await service.setEnabled(true);
    await Future<void>.delayed(Duration.zero);

    service.captureCurrentEventAsOverride();
    await Future<void>.delayed(Duration.zero);

    final List<CalendarMuteTransition> transitions = <CalendarMuteTransition>[];
    final StreamSubscription<CalendarMuteTransition> sub = service.transitions.listen(transitions.add);

    // Event ends, no new event.
    currentEvent = null;
    streamHandler.sink?.success(null);
    await Future<void>.delayed(Duration.zero);

    expect(transitions, isEmpty);

    await sub.cancel();
    service.dispose();
  });

  test('setEnabled(false) during an active event emits no transition', () async {
    final SilentModeService silent = await buildSilentMode();
    final CalendarAutoMuteService service = CalendarAutoMuteService(silent);
    await service.init();

    currentEvent = <Object?, Object?>{
      'id': 'event-1',
      'title': 'Daily standup',
      'endTime': DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch,
    };
    await service.setEnabled(true);
    await Future<void>.delayed(Duration.zero);

    final List<CalendarMuteTransition> transitions = <CalendarMuteTransition>[];
    final StreamSubscription<CalendarMuteTransition> sub = service.transitions.listen(transitions.add);

    await service.setEnabled(false);
    await Future<void>.delayed(Duration.zero);

    expect(transitions, isEmpty);

    await sub.cancel();
    service.dispose();
  });

  test('switching from an overridden event to a fresh event emits a natural activation', () async {
    final SilentModeService silent = await buildSilentMode();
    final CalendarAutoMuteService service = CalendarAutoMuteService(silent);
    await service.init();

    currentEvent = <Object?, Object?>{
      'id': 'event-1',
      'title': 'Daily standup',
      'endTime': DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch,
    };
    await service.setEnabled(true);
    await Future<void>.delayed(Duration.zero);

    service.captureCurrentEventAsOverride();
    await Future<void>.delayed(Duration.zero);

    final List<CalendarMuteTransition> transitions = <CalendarMuteTransition>[];
    final StreamSubscription<CalendarMuteTransition> sub = service.transitions.listen(transitions.add);

    // The override event ends and a new one begins.
    currentEvent = <Object?, Object?>{
      'id': 'event-2',
      'title': 'Sync',
      'endTime': DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch,
    };
    streamHandler.sink?.success(null);
    await Future<void>.delayed(Duration.zero);

    expect(transitions.length, 1);
    expect(transitions.single, isA<CalendarMuteActivated>());
    expect((transitions.single as CalendarMuteActivated).event.id, 'event-2');

    await sub.cancel();
    service.dispose();
  });
}
