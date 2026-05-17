import 'package:anchwatt/main/services/launch_at_login_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MethodChannel channel = MethodChannel('com.anchwatt/launch_at_login');

  late List<MethodCall> calls;
  late bool nativeEnabled;
  late PlatformException? nativeError;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    calls = <MethodCall>[];
    nativeEnabled = false;
    nativeError = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall call) async {
        calls.add(call);

        final PlatformException? error = nativeError;
        if (error != null && call.method == 'setEnabled') {
          throw error;
        }

        switch (call.method) {
          case 'isEnabled':
            return nativeEnabled;
          case 'setEnabled':
            nativeEnabled = call.arguments as bool;

            return null;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });

  test('refresh reads the native state into the notifier', () async {
    nativeEnabled = true;

    final LaunchAtLoginService service = LaunchAtLoginService();
    await service.refresh();

    expect(service.isEnabled, true);
    expect(calls.single.method, 'isEnabled');
  });

  test('setEnabled(true) sends the call and updates the notifier', () async {
    final LaunchAtLoginService service = LaunchAtLoginService();

    await service.setEnabled(true);

    expect(service.isEnabled, true);
    expect(nativeEnabled, true);
    expect(calls.single.method, 'setEnabled');
    expect(calls.single.arguments, true);
  });

  test('setEnabled(false) sends the call and updates the notifier', () async {
    nativeEnabled = true;

    final LaunchAtLoginService service = LaunchAtLoginService();
    await service.refresh();

    await service.setEnabled(false);

    expect(service.isEnabled, false);
    expect(nativeEnabled, false);
    expect(calls.last.method, 'setEnabled');
    expect(calls.last.arguments, false);
  });

  test('setEnabled rethrows on native failure and resyncs from native state', () async {
    nativeError = PlatformException(code: 'sm_app_service_failed', message: 'unsigned build');

    final LaunchAtLoginService service = LaunchAtLoginService();

    await expectLater(service.setEnabled(true), throwsA(isA<PlatformException>()));

    // After the failure the service re-queries the bridge so the UI mirrors
    // the OS-side status — which remained `false` because register() failed.
    expect(service.isEnabled, false);
    expect(calls.map((c) => c.method).toList(), <String>['setEnabled', 'isEnabled']);
  });

  test('setEnabled always forwards the call (no local short-circuit on identical value)', () async {
    final LaunchAtLoginService service = LaunchAtLoginService();

    // The source of truth lives on the native side, so the service must
    // forward every call rather than skip when the value looks unchanged.
    await service.setEnabled(false);

    expect(calls.single.method, 'setEnabled');
    expect(calls.single.arguments, false);
  });
}
