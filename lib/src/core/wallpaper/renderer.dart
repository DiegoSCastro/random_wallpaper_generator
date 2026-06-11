import 'dart:ui' as ui;

import 'package:random_wallpaper_generator/src/core/wallpaper/generator.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/generator_params.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_point.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/palette.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/pixel_rasterizer.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/render_pipeline.dart';

/// Renders a list of [WallpaperPoint] into a [ui.Image].
///
/// Design rules (v0.2 — visual richness pass):
///   1. NO additive blending. Each pixel writes a single alpha. Additive
///      blending on 200k points creates the "milky fog" effect that loses
///      the underlying geometry.
///   2. Zoom to content. Compute the tight bounding box of the points and
///      translate+scale so the structure fills ~95% of the canvas. Sparsely
///      distributed attractors (Clifford, Aizawa) no longer leave 50% empty.
///   3. Full-palette gradient. Every point is colored by lerping along the
///      full palette gradient (not just 2 picks), so the palette is
///      visible end-to-end.
///   4. Live palette blending. [paletteA] -> [paletteB] is interpolated by
///      [blend] (0..1) so we can animate re-paletting at 60fps without
///      regenerating geometry.
///   5. Sparkle layer. 8% extra randomly-placed bright points add density
///      and break the "pobre" look of pure trajectory dots.
class WallpaperRenderer {
  const WallpaperRenderer();

  /// Renders [points] into an image of [width]x[height].
  ///
  /// [paletteA] and [paletteB] are blended by [blend] (0..1). When the
  /// caller wants a static palette, pass the same value for both and 0.
  ui.Image render({
    required List<WallpaperPoint> points,
    required WallpaperPalette paletteA,
    required WallpaperPalette paletteB,
    required double blend,
    required GeneratorParams params,
    required int width,
    required int height,
  }) {
    final colorsA = paletteA.colors();
    final colorsB = paletteB.colors();
    final blended = _blendPalettes(colorsA, colorsB, blend);
    final bg = blended.first;
    final trail = blended.skip(1).toList();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );
    return RenderPipeline.decodePixels(
      PixelBuffer(width: width, height: height, pixels: pixels),
    );
  }

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

    // 4. Single underglow pass + per-point gradient pass.
    //
    // Pre-compute a lookup table of trail colors (256 entries) so the
    // hot loop is just a table lookup + lerp against an alpha.
    const lutSize = 256;
    final lut = _buildLut(trail, lutSize);
    final n = points.length;

    // Underglow pass: 1 cheap filled circle per point, low alpha.
    final midColor = lut[lutSize ~/ 2];
    final glowPaint = Paint()
      ..color = midColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;
    for (var i = 0; i < n; i++) {
      final p = points[i];
      final t = i / n;
      final alpha = (0.05 + 0.18 * t).clamp(0.05, 0.23);
      glowPaint.color = midColor.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(p.x * width * scale + offsetX, p.y * height * scale + offsetY),
        1.5,
        glowPaint,
      );
    }

    // Core pass: 1 anti-aliased circle per point, color from gradient LUT.
    final corePaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (var i = 0; i < n; i++) {
      final p = points[i];
      final t = i / n;
      final lutIdx = (t * (lutSize - 1)).floor();
      final c = lut[lutIdx];
      // Alpha curve: older = dim, newer = bright. The head of the
      // trajectory pops, the tail fades into the gradient.
      final alpha = (0.35 + 0.55 * t).clamp(0.35, 0.92);
      corePaint.color = c.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(p.x * width * scale + offsetX, p.y * height * scale + offsetY),
        0.75,
        corePaint,
      );
    }

    final picture = recorder.endRecording();
    return picture.toImageSync(width, height);
  }

  // ---------- helpers ----------

  static List<Color> _blendPalettes(
    List<Color> a,
    List<Color> b,
    double t,
  ) {
    final len = a.length > b.length ? a.length : b.length;
    final out = <Color>[];
    for (var i = 0; i < len; i++) {
      final ca = i < a.length ? a[i] : a.last;
      final cb = i < b.length ? b[i] : b.last;
      out.add(Color.lerp(ca, cb, t) ?? ca);
    }
    return out;
  }

  static List<Color> _buildLut(List<Color> trail, int size) {
    if (trail.isEmpty) {
      return List<Color>.filled(size, const Color(0xFFFFFFFF));
    }
    if (trail.length == 1) {
      return List<Color>.filled(size, trail.first);
    }
    final out = <Color>[];
    for (var i = 0; i < size; i++) {
      final t = i / (size - 1) * (trail.length - 1);
      final lo = t.floor().clamp(0, trail.length - 1);
      final hi = (lo + 1).clamp(0, trail.length - 1);
      final frac = t - lo;
      out.add(Color.lerp(trail[lo], trail[hi], frac) ?? trail[lo]);
    }
    return out;
  }
}
