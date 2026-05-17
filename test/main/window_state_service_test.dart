import 'package:anchwatt/main/services/window_state_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MethodChannel channel = MethodChannel('com.anchwatt/window_state');

  late List<MethodCall> calls;
  late bool nativeHidden;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    calls = <MethodCall>[];
    nativeHidden = false;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall call) async {
        calls.add(call);
        switch (call.method) {
          case 'isWindowHidden':
            return nativeHidden;
          case 'showWindow':
            nativeHidden = false;

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

  test('isWindowHidden forwards the native value', () async {
    nativeHidden = true;
    final WindowStateService service = WindowStateService();

    expect(await service.isWindowHidden(), true);
    expect(calls.single.method, 'isWindowHidden');
  });

  test('isWindowHidden defaults to false when the native call fails', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall call) async {
        throw PlatformException(code: 'boom');
      },
    );

    final WindowStateService service = WindowStateService();
    expect(await service.isWindowHidden(), false);
  });

  test('showWindow invokes the native method', () async {
    nativeHidden = true;
    final WindowStateService service = WindowStateService();

    await service.showWindow();

    expect(calls.single.method, 'showWindow');
    expect(nativeHidden, false);
  });
}
