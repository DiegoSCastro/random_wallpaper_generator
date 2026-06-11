import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:random_wallpaper_generator/src/core/wallpaper/models/generator_params.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_point.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/palette.dart';

/// Renders a list of [WallpaperPoint] into a [ui.Image] using Canvas operations.
///
/// Design rules (v0.1.1 — visual polish pass):
///   1. NO additive blending. Each pixel writes a single alpha. Additive
///      blending on 200k points creates the "milky fog" effect that loses
///      the underlying geometry.
///   2. Zoom to content. Compute the tight bounding box of the points and
///      translate+scale so the structure fills ~95% of the canvas. Sparsely
///      distributed attractors (Clifford, Aizawa) no longer leave 50% empty.
///   3. Point-based draw, not polyline. Building a single Path of 200k
///      line segments with anti-aliasing is too slow for interactive use.
///      Instead, draw the points directly with per-point alpha that fades
///      along the trajectory (older points = dimmer).
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

    // Subtle vignette: darken the corners so the eye is drawn to the center.
    if (trail.isNotEmpty) {
      final vignette = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.30)],
          stops: const [0.55, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        vignette,
      );
    }

    if (points.isEmpty) {
      final picture = recorder.endRecording();
      return picture.toImageSync(width, height);
    }

    // 1. Compute tight bounding box of the points.
    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;
    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    final contentW = (maxX - minX).abs() < 1e-9 ? 1.0 : (maxX - minX);
    final contentH = (maxY - minY).abs() < 1e-9 ? 1.0 : (maxY - minY);

    // 2. Scale to fill ~95% of the canvas.
    const fillFactor = 0.95;
    final scaleX = (width * fillFactor) / (contentW * width);
    final scaleY = (height * fillFactor) / (contentH * height);
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // 3. Compute offset to center the drawn content.
    final drawnW = contentW * width * scale;
    final drawnH = contentH * height * scale;
    final offsetX = (width - drawnW) / 2 - minX * width * scale;
    final offsetY = (height - drawnH) / 2 - minY * height * scale;

    // 4. Draw the points. Two passes:
    //   (a) a soft colored underglow (one big radius, low alpha) — gives
    //       the structure some weight without a heavy blend;
    //   (b) a tight colored core (small radius) — defines the geometry.
    // Both pass use SrcOver (no BlendMode.plus).
    final glowColor = trail.length >= 2 ? trail[trail.length ~/ 2] : trail.first;
    final coreColor = trail.last;
    final n = points.length;

    // Underglow pass: one filled circle per point, low alpha, slightly larger.
    // Use StrokeCap.butt for the circles to avoid expensive round caps.
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;
    for (var i = 0; i < n; i++) {
      final p = points[i];
      // Newer points (high index) brighter than older points (low index).
      final t = i / n; // 0..1
      final alpha = (0.04 + 0.18 * t).clamp(0.04, 0.22);
      glowPaint.color = glowColor.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(p.x * width * scale + offsetX, p.y * height * scale + offsetY),
        1.6,
        glowPaint,
      );
    }

    // Core pass: smaller, brighter, anti-aliased.
    final corePaint = Paint()
      ..color = coreColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (var i = 0; i < n; i++) {
      final p = points[i];
      final t = i / n;
      final alpha = (0.45 + 0.45 * t).clamp(0.45, 0.90);
      corePaint.color = coreColor.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(p.x * width * scale + offsetX, p.y * height * scale + offsetY),
        0.7,
        corePaint,
      );
    }

    final picture = recorder.endRecording();
    return picture.toImageSync(width, height);
  }
}
