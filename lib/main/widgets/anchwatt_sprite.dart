import 'package:anchwatt/main/models.dart';
import 'package:flutter/material.dart';

class AnchwattSprite extends StatefulWidget {
  static const Duration _breathDuration = Duration(seconds: 3);
  static const Duration _evolutionTransitionDuration = Duration(milliseconds: 400);
  static const Duration _mutedTransitionDuration = Duration(milliseconds: 300);
  static const double _breathAmplitude = 1.02;
  static const double _mutedSaturation = 0.4;

  final Evolution evolution;
  final bool muted;

  const AnchwattSprite({
    required this.evolution,
    this.muted = false,
    super.key,
  });

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
        builder: (_, saturation, _) => ColorFiltered(
          colorFilter: ColorFilter.matrix(_saturationMatrix(saturation)),
          child: AnimatedSwitcher(
            duration: AnchwattSprite._evolutionTransitionDuration,
            child: Image.asset(
              widget.evolution.assetPath,
              key: ValueKey<Evolution>(widget.evolution),
              filterQuality: FilterQuality.none,
              fit: BoxFit.contain,
            ),
          ),
        ),
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
}
