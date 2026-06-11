import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:random_wallpaper_generator/src/core/wallpaper/models/generator_params.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_point.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/palette.dart';

/// Renders a list of [WallpaperPoint] into a [ui.Image] using Canvas operations.
///
/// The renderer is pure: it takes the points + a palette and produces an
/// image. No I/O. Must run on the root isolate (Canvas APIs are unavailable
/// in background isolates on iOS).
class WallpaperRenderer {
  const WallpaperRenderer();

  /// Renders [points] into an image of [width]x[height] using [palette].
  ui.Image render({
    required List<WallpaperPoint> points,
    required WallpaperPalette palette,
    required GeneratorParams params,
    required int width,
    required int height,
  }) {
    final colors = palette.colors();
    final bg = colors.first;
    final trail = colors.skip(1).toList();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );

    // Background.
    final bgPaint = Paint()..color = bg;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      bgPaint,
    );

    // Subtle radial gradient overlay for depth.
    if (trail.isNotEmpty) {
      final overlay = Paint()
        ..shader = RadialGradient(
          colors: [trail.last.withValues(alpha: 0.18), Colors.transparent],
          stops: const [0.0, 0.7],
        ).createShader(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        overlay,
      );
    }

    // Trajectory points. Additive blending for the glow effect.
    final glowColor = trail.length >= 2 ? trail[trail.length ~/ 2] : trail.first;
    final coreColor = trail.last;

    // Outer glow.
    _drawPoints(
      canvas,
      points,
      width,
      height,
      glowColor.withValues(alpha: 0.18),
      3.5,
    );
    // Mid glow.
    _drawPoints(
      canvas,
      points,
      width,
      height,
      glowColor.withValues(alpha: 0.35),
      1.8,
    );
    // Core (sharp).
    _drawPoints(
      canvas,
      points,
      width,
      height,
      coreColor.withValues(alpha: 0.95),
      0.8,
    );

    final picture = recorder.endRecording();
    return picture.toImageSync(width, height);
  }

  void _drawPoints(
    Canvas canvas,
    List<WallpaperPoint> points,
    int width,
    int height,
    Color color,
    double radius,
  ) {
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.fill
      ..color = color;
    for (final p in points) {
      canvas.drawCircle(
        Offset(p.x * width, p.y * height),
        radius,
        paint,
      );
    }
  }
}
