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
}
