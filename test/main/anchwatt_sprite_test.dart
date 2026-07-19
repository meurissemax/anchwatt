import 'package:anchwatt/main/widgets/anchwatt_sprite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnchwattSprite.filterModeFor', () {
    test('DND desaturation wins over shiny', () {
      expect(
        AnchwattSprite.filterModeFor(muted: true, isShiny: true),
        SpriteFilterMode.desaturate,
      );
    });

    test('DND desaturates when not shiny', () {
      expect(
        AnchwattSprite.filterModeFor(muted: true, isShiny: false),
        SpriteFilterMode.desaturate,
      );
    });

    test('shiny recolours when not in DND', () {
      expect(
        AnchwattSprite.filterModeFor(muted: false, isShiny: true),
        SpriteFilterMode.shiny,
      );
    });

    test('no filter when neither DND nor shiny', () {
      expect(
        AnchwattSprite.filterModeFor(muted: false, isShiny: false),
        SpriteFilterMode.none,
      );
    });
  });
}
