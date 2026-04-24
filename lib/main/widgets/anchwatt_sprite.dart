import 'package:anchwatt/main/models.dart';
import 'package:flutter/material.dart';

class AnchwattSprite extends StatefulWidget {
  static const Duration _breathDuration = Duration(seconds: 3);
  static const Duration _evolutionTransitionDuration = Duration(milliseconds: 400);
  static const double _breathAmplitude = 1.02;

  final Evolution evolution;

  const AnchwattSprite({
    required this.evolution,
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
  }
}
