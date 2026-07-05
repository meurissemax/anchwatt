import 'package:anchwatt/styles/borders.dart';
import 'package:anchwatt/styles/colors.dart';
import 'package:flutter/material.dart';

// The bar owns the "fill up and roll over" pacing entirely on the UI side: the
// ViewModel's level/XP are the instant source of truth, and this widget catches
// up frame-by-frame. Keeping the animation here (never in the model) means a
// throttled ticker can only ever make the bar lag — it can never freeze
// leveling with the bar pinned full, which is what used to happen.
class XpProgressBar extends StatefulWidget {
  final int level;
  final double progress;
  final Color color;

  const XpProgressBar({
    required this.level,
    required this.progress,
    required this.color,
    super.key,
  });

  @override
  State<XpProgressBar> createState() => _XpProgressBarState();
}

class _XpProgressBarState extends State<XpProgressBar> with SingleTickerProviderStateMixin {
  /* Static variables */

  static const double _barHeight = 8;
  // One fill segment per level crossed; a plain progress change animates over a
  // single segment of the same length, so the bar always moves at one pace.
  static const Duration _segmentDuration = Duration(milliseconds: 350);

  /* Variables */

  late final AnimationController _controller;
  Animation<double> _animation = const AlwaysStoppedAnimation<double>(0);
  late int _displayedLevel;

  /* Methods */

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);

    // Show the first values immediately; every later change flows through
    // _animateTo, which decides whether to roll over or snap.
    _displayedLevel = widget.level;
    _animation = AlwaysStoppedAnimation<double>(widget.progress.clamp(0, 1));
  }

  @override
  void didUpdateWidget(XpProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.level == oldWidget.level && widget.progress == oldWidget.progress) {
      return;
    }

    _animateTo(level: widget.level, progress: widget.progress.clamp(0, 1));
  }

  void _animateTo({required int level, required double progress}) {
    final double from = _animation.value;
    final int delta = level - _displayedLevel;
    _displayedLevel = level;

    // Only a single-palier advance is a genuine in-app level-up — at these XP
    // rates one grant never crosses more than one palier. A larger jump or a
    // drop is a state load (the initial read from storage on boot, or a debug
    // reset), so snap to it instead of replaying a roll-over for every palier.
    if (delta != 0 && delta != 1) {
      _controller.stop();

      setState(() => _animation = AlwaysStoppedAnimation<double>(progress));

      return;
    }

    // delta == 1 fills the current palier then rolls over into the next;
    // delta == 0 is an in-palier gain that just glides to the new fill.
    final List<TweenSequenceItem<double>> items = delta == 1
        ? [_segment(from, 1), _segment(0, progress)]
        : [_segment(from, progress)];

    setState(() {
      _controller.duration = _segmentDuration * items.length;
      _animation = _controller.drive(TweenSequence<double>(items));
    });

    _controller.forward(from: 0);
  }

  TweenSequenceItem<double> _segment(double begin, double end) => TweenSequenceItem<double>(
    tween: Tween<double>(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOutCubic)),
    weight: 1,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _barHeight,
      child: LayoutBuilder(
        builder: (_, constraints) => Stack(
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
              child: AnimatedBuilder(
                animation: _animation,
                builder: (_, _) => SizedBox(
                  width: constraints.maxWidth * _animation.value.clamp(0, 1),
                  height: _barHeight,
                  child: ColoredBox(color: widget.color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
