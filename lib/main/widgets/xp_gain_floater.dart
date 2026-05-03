import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/styles/texts.dart';
import 'package:flutter/material.dart';

class XpGainFloater extends StatefulWidget {
  static const Duration _totalDuration = Duration(milliseconds: 900);
  static const double _riseDistance = 24;
  static const double _fadeInWeight = 200;
  static const double _holdWeight = 500;
  static const double _fadeOutWeight = 200;

  final int amount;
  final Color color;
  final VoidCallback onCompleted;

  const XpGainFloater({
    required this.amount,
    required this.color,
    required this.onCompleted,
    super.key,
  });

  @override
  State<XpGainFloater> createState() => _XpGainFloaterState();
}

class _XpGainFloaterState extends State<XpGainFloater> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _translateY;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: XpGainFloater._totalDuration,
    );

    _opacity = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1),
        weight: XpGainFloater._fadeInWeight,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1),
        weight: XpGainFloater._holdWeight,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0),
        weight: XpGainFloater._fadeOutWeight,
      ),
    ]).animate(_controller);

    _translateY =
        Tween<double>(
          begin: 0,
          end: -XpGainFloater._riseDistance,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut,
          ),
        );

    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _translateY.value),
            child: child,
          ),
        ),
        child: Text(
          l10n.anchwattXpGain(widget.amount),
          style: textXpGainFloater.copyWith(color: widget.color),
        ),
      ),
    );
  }
}
