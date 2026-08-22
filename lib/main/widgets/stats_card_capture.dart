import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

// Renders [card] to a PNG entirely off-screen, so the result is deterministic
// and independent of the visible window's size or the display's DPI.
//
// The card is mounted in a live [OverlayEntry] translated far outside the
// viewport: it genuinely lays out and paints (unlike Offstage/Visibility, which
// skip painting and would leave RepaintBoundary.toImage with nothing to grab),
// while staying invisible to the user. Callers must precache any images the card
// draws (the sprite, the logo) before calling, otherwise the first painted frame
// captures blank boxes.
//
// [pixelRatio] 3 against a fixed 600 logical-px width yields an ~1800px PNG.
Future<Uint8List> captureStatsCard({
  required OverlayState overlay,
  required Widget card,
}) async {
  const double logicalWidth = 600;
  const double pixelRatio = 3;
  const Offset offScreen = Offset(-10000, -10000);

  final GlobalKey boundaryKey = GlobalKey();

  final OverlayEntry entry = OverlayEntry(
    builder: (_) => Positioned(
      left: 0,
      top: 0,
      child: Transform.translate(
        offset: offScreen,
        child: Material(
          type: MaterialType.transparency,
          child: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: logicalWidth,
              child: card,
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  try {
    // Let the entry lay out and paint before grabbing its layer.
    await WidgetsBinding.instance.endOfFrame;

    final RenderRepaintBoundary boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

    try {
      final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);

      if (data == null) {
        throw StateError('Stats card capture produced no PNG bytes');
      }

      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    entry.remove();
  }
}
