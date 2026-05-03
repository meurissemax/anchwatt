import 'dart:math';

import 'package:anchwatt/main/view_models/anchwatt_view_model.dart';
import 'package:anchwatt/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PetGestureSurface extends StatefulWidget {
  /* Static variables */

  static const Duration _sparkleLifetime = Duration(milliseconds: 700);
  static const Duration _sparkleSpawnInterval = Duration(milliseconds: 100);
  static const int _sparkleMaxConcurrent = 12;
  static const double _sparkleMinSize = 14;
  static const double _sparkleMaxSize = 22;
  static const double _sparkleDriftMin = 18;
  static const double _sparkleDriftMax = 36;
  static const double _sparkleAngleCenter = -pi / 2;
  static const double _sparkleAngleSpread = pi / 3;

  /* Variables */

  final Widget child;

  /* Constructor */

  const PetGestureSurface({
    required this.child,
    super.key,
  });

  @override
  State<PetGestureSurface> createState() => _PetGestureSurfaceState();
}

class _PetGestureSurfaceState extends State<PetGestureSurface> {
  /* Variables */

  final List<_SparkleEntry> _sparkles = [];
  final Random _random = Random();
  DateTime _lastSparkleAt = DateTime.fromMillisecondsSinceEpoch(0);
  Size _size = Size.zero;

  /* Methods */

  void _onPanStart(DragStartDetails details) {
    _lastSparkleAt = DateTime.fromMillisecondsSinceEpoch(0);
    context.read<AnchwattViewModel>().onPetTick();
    _maybeSpawnSparkle(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final Offset position = details.localPosition;

    final bool insideBounds =
        position.dx >= 0 && position.dx <= _size.width && position.dy >= 0 && position.dy <= _size.height;

    if (!insideBounds) {
      return;
    }

    context.read<AnchwattViewModel>().onPetTick();
    _maybeSpawnSparkle(position);
  }

  void _maybeSpawnSparkle(Offset position) {
    final DateTime now = DateTime.now();
    if (now.difference(_lastSparkleAt) < PetGestureSurface._sparkleSpawnInterval) {
      return;
    }

    if (_sparkles.length >= PetGestureSurface._sparkleMaxConcurrent) {
      return;
    }

    _lastSparkleAt = now;

    final double angle =
        PetGestureSurface._sparkleAngleCenter + (_random.nextDouble() * 2 - 1) * PetGestureSurface._sparkleAngleSpread;
    final double distance =
        PetGestureSurface._sparkleDriftMin +
        _random.nextDouble() * (PetGestureSurface._sparkleDriftMax - PetGestureSurface._sparkleDriftMin);
    final double size =
        PetGestureSurface._sparkleMinSize +
        _random.nextDouble() * (PetGestureSurface._sparkleMaxSize - PetGestureSurface._sparkleMinSize);
    final Color color = _random.nextBool() ? colorSparkleCore : colorSparkleGlow;

    setState(() {
      _sparkles.add(
        _SparkleEntry(
          key: UniqueKey(),
          spawn: position,
          angle: angle,
          distance: distance,
          size: size,
          color: color,
        ),
      );
    });
  }

  void _onSparkleCompleted(Key key) {
    setState(() {
      _sparkles.removeWhere((entry) => entry.key == key);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      child: LayoutBuilder(
        builder: (_, constraints) {
          _size = Size(constraints.maxWidth, constraints.maxHeight);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              widget.child,
              for (final _SparkleEntry entry in _sparkles)
                Positioned(
                  left: entry.spawn.dx - entry.size / 2,
                  top: entry.spawn.dy - entry.size / 2,
                  child: IgnorePointer(
                    child: _SparkleParticle(
                      key: entry.key,
                      angle: entry.angle,
                      distance: entry.distance,
                      size: entry.size,
                      color: entry.color,
                      onCompleted: () => _onSparkleCompleted(entry.key),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SparkleEntry {
  final Key key;
  final Offset spawn;
  final double angle;
  final double distance;
  final double size;
  final Color color;

  const _SparkleEntry({
    required this.key,
    required this.spawn,
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
  });
}

class _SparkleParticle extends StatefulWidget {
  /* Static variables */

  static const double _fadeInWeight = 100;
  static const double _holdWeight = 200;
  static const double _fadeOutWeight = 400;

  /* Variables */

  final double angle;
  final double distance;
  final double size;
  final Color color;
  final VoidCallback onCompleted;

  /* Constructor */

  const _SparkleParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.onCompleted,
    super.key,
  });

  @override
  State<_SparkleParticle> createState() => _SparkleParticleState();
}

class _SparkleParticleState extends State<_SparkleParticle> with SingleTickerProviderStateMixin {
  /* Variables */

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _drift;

  /* Methods */

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: PetGestureSurface._sparkleLifetime,
    );

    _opacity = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1),
        weight: _SparkleParticle._fadeInWeight,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1),
        weight: _SparkleParticle._holdWeight,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0),
        weight: _SparkleParticle._fadeOutWeight,
      ),
    ]).animate(_controller);

    _drift = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
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
    final double dx = cos(widget.angle) * widget.distance;
    final double dy = sin(widget.angle) * widget.distance;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Transform.translate(
        offset: Offset(dx * _drift.value, dy * _drift.value),
        child: Opacity(
          opacity: _opacity.value,
          child: child,
        ),
      ),
      child: Icon(
        Icons.auto_awesome,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}
