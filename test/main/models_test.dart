import 'package:anchwatt/main/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnchwattSettings.xpForEvent', () {
    test('usbToggle at level 1 with full volume awards base * maxVolumeMultiplier', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        systemVolume: 1,
      );

      expect(xp, 30);
    });

    test('usbToggle with zero volume awards 0 XP (anti-farming)', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        systemVolume: 0,
      );

      expect(xp, 0);
    });

    test('usbToggle scales with system volume between 0 and 1', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        systemVolume: 0.5,
      );

      expect(xp, 15);
    });

    test('usbToggle scales with player level', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 50,
        systemVolume: 1,
      );

      expect(xp, 471);
    });

    test('usbToggle clamps systemVolume above 1 to 1', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        systemVolume: 1.5,
      );

      expect(xp, 30);
    });

    test('usbToggle clamps negative systemVolume to 0', () {
      final int xp = AnchwattSettings.xpForEvent(
        type: AnchwattEventType.usbToggle,
        level: 1,
        systemVolume: -0.2,
      );

      expect(xp, 0);
    });

    test('usbToggle without systemVolume triggers assertion', () {
      expect(
        () => AnchwattSettings.xpForEvent(
          type: AnchwattEventType.usbToggle,
          level: 1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
