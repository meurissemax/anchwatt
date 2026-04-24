import 'package:anchwatt/styles/borders.dart';
import 'package:anchwatt/styles/colors.dart';
import 'package:flutter/material.dart';

class XpProgressBar extends StatelessWidget {
  static const double _barHeight = 8;
  static const Duration _animationDuration = Duration(milliseconds: 350);

  final double progress;
  final Color color;

  const XpProgressBar({
    required this.progress,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _barHeight,
      child: LayoutBuilder(
        builder: (_, constraints) => TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 0,
            end: progress.clamp(0, 1),
          ),
          duration: _animationDuration,
          curve: Curves.easeOutCubic,
          builder: (_, value, _) => Stack(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: colorXpProgressBarTrack,
                  borderRadius: borderRadiusXpBar,
                ),
                child: SizedBox.expand(),
              ),
              ClipRRect(
                borderRadius: borderRadiusXpBar,
                child: SizedBox(
                  width: constraints.maxWidth * value,
                  height: _barHeight,
                  child: ColoredBox(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
