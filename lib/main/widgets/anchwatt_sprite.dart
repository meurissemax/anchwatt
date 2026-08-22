import 'dart:math';

import 'package:anchwatt/main/models.dart';
import 'package:material_ui/material_ui.dart';

// The colour filter to apply to the sprite. Selection is mutually exclusive
// and follows a strict precedence: DND desaturation wins over the shiny
// recolour, which wins over no filter at all.
enum SpriteFilterMode { desaturate, shiny, none }

class AnchwattSprite extends StatefulWidget {
  static const Duration _breathDuration = Duration(seconds: 3);
  static const Duration _evolutionTransitionDuration = Duration(milliseconds: 400);
  static const Duration _mutedTransitionDuration = Duration(milliseconds: 300);
  static const double _breathAmplitude = 1.02;
  static const double _mutedSaturation = 0.4;

  final Evolution evolution;
  final bool muted;
  final bool isShiny;

  const AnchwattSprite({
    required this.evolution,
    this.muted = false,
    this.isShiny = false,
    super.key,
  });

  // Resolves the active filter from the two visual flags. DND (muted) takes
  // precedence over shiny so a shiny sprite still desaturates while "Ne pas
  // déranger" is active.
  @visibleForTesting
  static SpriteFilterMode filterModeFor({required bool muted, required bool isShiny}) {
    if (muted) {
      return SpriteFilterMode.desaturate;
    }

    if (isShiny) {
      return SpriteFilterMode.shiny;
    }

    return SpriteFilterMode.none;
  }

  @override
  State<AnchwattSprite> createState() => _AnchwattSpriteState();
}

class _AnchwattSpriteState extends State<AnchwattSprite> with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;
  late final Animation<double> _breath;

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: AnchwattSprite._breathDuration,
    )..repeat(reverse: true);

    _breath =
        Tween<double>(
          begin: 1,
          end: AnchwattSprite._breathAmplitude,
        ).animate(
          CurvedAnimation(
            parent: _breathController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _breath,
      child: TweenAnimationBuilder<double>(
        duration: AnchwattSprite._mutedTransitionDuration,
        curve: Curves.easeInOut,
        tween: Tween<double>(
          end: widget.muted ? AnchwattSprite._mutedSaturation : 1,
        ),
        builder: (_, saturation, _) {
          final SpriteFilterMode mode = AnchwattSprite.filterModeFor(
            muted: widget.muted,
            isShiny: widget.isShiny,
          );

          final ColorFilter filter = switch (mode) {
            SpriteFilterMode.shiny => ColorFilter.matrix(
              _hueRotationMatrix(AnchwattSettings.shinyHueRotationDegrees),
            ),
            // Both desaturate and none use the animated saturation matrix: when
            // not muted the tween settles at 1 (identity), so `none` applies no
            // visible change while still animating the un-desaturation on DND exit.
            SpriteFilterMode.desaturate || SpriteFilterMode.none => ColorFilter.matrix(_saturationMatrix(saturation)),
          };

          return ColorFiltered(
            colorFilter: filter,
            child: AnimatedSwitcher(
              duration: AnchwattSprite._evolutionTransitionDuration,
              child: Image.asset(
                widget.evolution.assetPath,
                key: ValueKey<Evolution>(widget.evolution),
                filterQuality: FilterQuality.none,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }

  // Builds a saturation color matrix where `saturation` is the fraction of
  // colour retained (1 = original, 0 = full grayscale). The alpha row is left
  // untouched so the sprite's transparency is preserved.
  static List<double> _saturationMatrix(double saturation) {
    const double lumR = 0.2126;
    const double lumG = 0.7152;
    const double lumB = 0.0722;

    final double r = (1 - saturation) * lumR;
    final double g = (1 - saturation) * lumG;
    final double b = (1 - saturation) * lumB;

    return <double>[
      r + saturation, g, b, 0, 0, //
      r, g + saturation, b, 0, 0, //
      r, g, b + saturation, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }

  // Builds a luminance-preserving hue-rotation colour matrix for `degrees`. The
  // rows sum to 1, so neutral pixels (the black outline and eyes) and greys are
  // left effectively unchanged; only chroma is shifted. The alpha row is
  // untouched so the sprite's transparency is preserved. This is a linear-RGB
  // rotation (it differs slightly from an HSV rotation, which is acceptable —
  // the angle is tunable via [AnchwattSettings.shinyHueRotationDegrees]).
  static List<double> _hueRotationMatrix(double degrees) {
    final double a = degrees * pi / 180;
    final double c = cos(a);
    final double s = sin(a);

    const double lumR = 0.213;
    const double lumG = 0.715;
    const double lumB = 0.072;

    return <double>[
      lumR + c * (1 - lumR) - s * lumR, lumG - c * lumG - s * lumG, lumB - c * lumB + s * (1 - lumB), 0, 0, //
      lumR - c * lumR + s * 0.143, lumG + c * (1 - lumG) + s * 0.140, lumB - c * lumB - s * 0.283, 0, 0, //
      lumR - c * lumR - s * (1 - lumR), lumG - c * lumG + s * lumG, lumB + c * (1 - lumB) + s * lumB, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }
}
