import 'dart:math';

import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/view_models/anchwatt_view_model.dart';
import 'package:anchwatt/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PetGestureSurface extends StatefulWidget {
  /* Static variables */

  static const Duration _sparkleLifetime = Duration(milliseconds: 700);
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
    final _SparkleProfile profile = _SparkleProfile.of(context.read<AnchwattViewModel>().evolution);

    final DateTime now = DateTime.now();
    if (now.difference(_lastSparkleAt) < profile.spawnInterval) {
      return;
    }

    if (_sparkles.length >= profile.maxConcurrent) {
      return;
    }

    _lastSparkleAt = now;

    final double angle =
        PetGestureSurface._sparkleAngleCenter + (_random.nextDouble() * 2 - 1) * PetGestureSurface._sparkleAngleSpread;
    final double distance = profile.driftMin + _random.nextDouble() * (profile.driftMax - profile.driftMin);
    final double size = profile.minSize + _random.nextDouble() * (profile.maxSize - profile.minSize);
    final Color color = profile.colors[_random.nextInt(profile.colors.length)];
    final IconData icon = _random.nextDouble() < profile.boltChance ? Icons.bolt : Icons.auto_awesome;

    setState(() {
      _sparkles.add(
        _SparkleEntry(
          key: UniqueKey(),
          spawn: position,
          angle: angle,
          distance: distance,
          size: size,
          color: color,
          icon: icon,
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
                      icon: entry.icon,
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

enum _SparkleProfile {
  anchwatt(
    spawnInterval: Duration(milliseconds: 100),
    maxConcurrent: 12,
    minSize: 14,
    maxSize: 22,
    driftMin: 18,
    driftMax: 36,
    boltChance: 0,
    colors: [colorSparkleCore, colorSparkleGlow],
  ),
  lamperoie(
    spawnInterval: Duration(milliseconds: 80),
    maxConcurrent: 16,
    minSize: 15,
    maxSize: 25,
    driftMin: 22,
    driftMax: 46,
    boltChance: 0.25,
    colors: [colorSparkleCore, colorSparkleEmber, colorSparkleGlow],
  ),
  ohmassacre(
    spawnInterval: Duration(milliseconds: 60),
    maxConcurrent: 20,
    minSize: 16,
    maxSize: 28,
    driftMin: 26,
    driftMax: 56,
    boltChance: 0.5,
    colors: [colorSparkleCore, colorSparkleEmber, colorSparkleGlow, colorSparkleRose],
  );

  /* Variables */

  final Duration spawnInterval;
  final int maxConcurrent;
  final double minSize;
  final double maxSize;
  final double driftMin;
  final double driftMax;
  final double boltChance;
  final List<Color> colors;

  /* Constructor */

  const _SparkleProfile({
    required this.spawnInterval,
    required this.maxConcurrent,
    required this.minSize,
    required this.maxSize,
    required this.driftMin,
    required this.driftMax,
    required this.boltChance,
    required this.colors,
  });

  /* Methods */

  static _SparkleProfile of(Evolution evolution) {
    switch (evolution) {
      case Evolution.anchwatt:
        return _SparkleProfile.anchwatt;

      case Evolution.lamperoie:
        return _SparkleProfile.lamperoie;

      case Evolution.ohmassacre:
        return _SparkleProfile.ohmassacre;
    }
  }
}

class _SparkleEntry {
  final Key key;
  final Offset spawn;
  final double angle;
  final double distance;
  final double size;
  final Color color;
  final IconData icon;

  const _SparkleEntry({
    required this.key,
    required this.spawn,
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.icon,
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
  final IconData icon;
  final VoidCallback onCompleted;

  /* Constructor */

  const _SparkleParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.icon,
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
        widget.icon,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}
