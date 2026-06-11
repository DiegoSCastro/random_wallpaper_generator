import 'dart:math' as math;
import 'dart:typed_data';

import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_point.dart';

/// CPU RGBA rasterizer with no Flutter UI dependencies — safe for isolates.
class PixelRasterizer {
  const PixelRasterizer();

  /// Returns RGBA8888 bytes (R, G, B, A per pixel).
  Uint8List rasterize({
    required List<WallpaperPoint> points,
    required List<int> colorsArgb,
    required int width,
    required int height,
  }) {
    final pixels = Uint8List(width * height * 4);
    _fill(pixels, width, height, colorsArgb.first);

    if (colorsArgb.length > 1) {
      _applyVignette(pixels, width, height);
    }

    if (points.isEmpty) {
      return pixels;
    }

    var minX = double.infinity;
    var maxX = -double.infinity;
    var minY = double.infinity;
    var maxY = -double.infinity;
    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    final contentW = (maxX - minX).abs() < 1e-9 ? 1.0 : (maxX - minX);
    final contentH = (maxY - minY).abs() < 1e-9 ? 1.0 : (maxY - minY);

    const fillFactor = 0.95;
    final scaleX = (width * fillFactor) / (contentW * width);
    final scaleY = (height * fillFactor) / (contentH * height);
    final scale = math.min(scaleX, scaleY);

    final drawnW = contentW * width * scale;
    final drawnH = contentH * height * scale;
    final offsetX = (width - drawnW) / 2 - minX * width * scale;
    final offsetY = (height - drawnH) / 2 - minY * height * scale;

    final trail = colorsArgb.skip(1).toList();
    final glowColor = trail.length >= 2 ? trail[trail.length ~/ 2] : trail.first;
    final coreColor = trail.last;
    final n = points.length;

    for (var i = 0; i < n; i++) {
      final p = points[i];
      final t = i / n;
      final alpha = (0.04 + 0.18 * t).clamp(0.04, 0.22);
      _drawCircle(
        pixels,
        width,
        height,
        p.x * width * scale + offsetX,
        p.y * height * scale + offsetY,
        1.6,
        glowColor,
        alpha,
      );
    }

    for (var i = 0; i < n; i++) {
      final p = points[i];
      final t = i / n;
      final alpha = (0.45 + 0.45 * t).clamp(0.45, 0.90);
      _drawCircle(
        pixels,
        width,
        height,
        p.x * width * scale + offsetX,
        p.y * height * scale + offsetY,
        0.7,
        coreColor,
        alpha,
        antialias: true,
      );
    }

    return pixels;
  }

  static void _fill(Uint8List pixels, int width, int height, int argb) {
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    for (var y = 0; y < height; y++) {
      final row = y * width * 4;
      for (var x = 0; x < width; x++) {
        final i = row + x * 4;
        pixels[i] = r;
        pixels[i + 1] = g;
        pixels[i + 2] = b;
        pixels[i + 3] = 255;
      }
    }
  }

  static void _applyVignette(Uint8List pixels, int width, int height) {
    final cx = width / 2;
    final cy = height / 2;
    final maxDist = math.min(width, height) / 2 * 0.95;

    for (var y = 0; y < height; y++) {
      final row = y * width * 4;
      for (var x = 0; x < width; x++) {
        final dist = math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy)) / maxDist;
        if (dist <= 0.55) continue;
        final t = ((dist - 0.55) / 0.45).clamp(0.0, 1.0);
        final vignetteAlpha = 0.30 * t;
        final i = row + x * 4;
        _blendSrcOver(pixels, i, 0xFF000000, vignetteAlpha);
      }
    }
  }

  static void _drawCircle(
    Uint8List pixels,
    int width,
    int height,
    double cx,
    double cy,
    double radius,
    int argb,
    double alpha, {
    bool antialias = false,
  }) {
    if (alpha <= 0) return;

    final r = radius.ceil() + (antialias ? 1 : 0);
    final minX = math.max(0, (cx - r).floor());
    final maxX = math.min(width - 1, (cx + r).ceil());
    final minY = math.max(0, (cy - r).floor());
    final maxY = math.min(height - 1, (cy + r).ceil());
    final radiusSq = radius * radius;

    for (var y = minY; y <= maxY; y++) {
      final row = y * width * 4;
      final dy = y - cy;
      for (var x = minX; x <= maxX; x++) {
        final dx = x - cx;
        final distSq = dx * dx + dy * dy;
        if (distSq > (radius + 1) * (radius + 1)) continue;

        var pixelAlpha = alpha;
        if (antialias) {
          final dist = math.sqrt(distSq);
          if (dist > radius) {
            pixelAlpha *= (1 - (dist - radius)).clamp(0.0, 1.0);
          } else if (dist > radius - 1) {
            pixelAlpha *= (radius - dist + 1).clamp(0.0, 1.0);
          }
        } else if (distSq > radiusSq) {
          continue;
        }

        if (pixelAlpha <= 0) continue;
        _blendSrcOver(pixels, row + x * 4, argb, pixelAlpha);
      }
    }
  }

  static void _blendSrcOver(Uint8List pixels, int index, int argb, double effectiveAlpha) {
    final srcA = ((argb >> 24) & 0xFF) / 255.0 * effectiveAlpha;
    if (srcA <= 0) return;

    final srcR = (argb >> 16) & 0xFF;
    final srcG = (argb >> 8) & 0xFF;
    final srcB = argb & 0xFF;

    if (srcA >= 1) {
      pixels[index] = srcR;
      pixels[index + 1] = srcG;
      pixels[index + 2] = srcB;
      pixels[index + 3] = 255;
      return;
    }

    final dstR = pixels[index];
    final dstG = pixels[index + 1];
    final dstB = pixels[index + 2];
    final inv = 1 - srcA;

    pixels[index] = (srcR * srcA + dstR * inv).round();
    pixels[index + 1] = (srcG * srcA + dstG * inv).round();
    pixels[index + 2] = (srcB * srcA + dstB * inv).round();
    pixels[index + 3] = 255;
  }
}

/// RGBA buffer produced in an isolate and decoded on the UI isolate.
class PixelBuffer {
  const PixelBuffer({
    required this.width,
    required this.height,
    required this.pixels,
  });

  final int width;
  final int height;
  final Uint8List pixels;
}
