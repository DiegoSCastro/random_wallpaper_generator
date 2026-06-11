import 'dart:math' as math;
import 'dart:typed_data';

import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_point.dart';

/// CPU RGBA rasterizer with no Flutter UI dependencies — safe for isolates.
///
/// Design rules (v0.2 — visual richness pass):
///   1. Full-palette gradient. Each point is colored by lerping along the
///      full trail gradient (not just 2 picks), so the palette is
///      visible end-to-end. We pre-build a 256-entry LUT for speed.
///   2. No additive blending — just per-point SrcOver alpha. This avoids
///      the "milky fog" effect of additive on 200k points.
///   3. Zoom to content. Compute the tight bounding box and scale the
///      trajectory so it fills ~95% of the canvas. Sparsely distributed
///      attractors (Clifford, Aizawa) no longer leave 50% empty.
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

    if (points.isEmpty) {
      if (colorsArgb.length > 1) {
        _applyVignette(pixels, width, height);
      }
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
    final n = points.length;

    // Build a 256-entry gradient LUT so the hot loop is just an int
    // table lookup instead of a per-point Color.lerp.
    final lut = _buildLut(trail, 256);

    // Glow pass — one big radius, low alpha, single color (mid of trail).
    final glowColor = lut[128];
    for (var i = 0; i < n; i++) {
      final p = points[i];
      final t = i / n;
      final alpha = (0.05 + 0.18 * t).clamp(0.05, 0.23);
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

    // Core pass — small, anti-aliased, full palette gradient by index.
    for (var i = 0; i < n; i++) {
      final p = points[i];
      final t = i / n;
      final lutIdx = (t * 255).floor().clamp(0, 255);
      final c = lut[lutIdx];
      final alpha = (0.35 + 0.55 * t).clamp(0.35, 0.92);
      _drawCircle(
        pixels,
        width,
        height,
        p.x * width * scale + offsetX,
        p.y * height * scale + offsetY,
        0.7,
        c,
        alpha,
        antialias: true,
      );
    }

    // Soft bloom to give the structure a halo of color.
    // Asymmetric: stronger in the center, attenuated at the edges
    // (radial mask with smoothstep), so dark backgrounds don't get a
    // flat halo and light backgrounds don't get a washed-out cloth.
    if (trail.isNotEmpty) {
      _applyBloom(
        pixels,
        width,
        height,
        downscale: 4,
        strength: 0.60, // 1.5x the previous uniform 0.40 (center boost).
      );
    }

    // v0.3 — premium texture pass.
    // The bloom uses a nearest-neighbour upsample, so the raw stipple
    // grain still reads as high-frequency noise on close-up. We:
    //   1) downsample 2x with a 4-tap bilinear filter,
    //   2) upsample 2x with bilinear back to full resolution,
    //   3) blend the smoothed result over the source at [mix] alpha
    //      to keep the original colour but kill the grain.
    // Bilinear is critical: nearest just resamples the same dot edges.
    // mix=0.65 is enough to crush the 1-pixel stipple alternation
    // while leaving the low-frequency colour ribbon readable.
    _applyBilinearSmooth(pixels, width, height, mix: 0.65);

    // Subtle film grain — intensity 0.02 keeps it organic, not gritty.
    // Per-channel noise reads as luminance grain rather than colour
    // noise, which on a phone wallpaper looks like paper texture.
    _applyFineGrain(pixels, width, height, intensity: 0.02, seed: 0xA5F3);

    // Vignette goes LAST — after all the smooth, grain, and trail
    // work is done. If we applied it to the background first the
    // bright points would paint over the corner darkening, killing
    // the "framed" premium look. Here it darkens everything — the
    // empty corners and the bright centre alike — so the eye reads
    // a consistent radial frame.
    if (colorsArgb.length > 1) {
      _applyVignette(pixels, width, height);
    }

    return pixels;
  }

  // ---------- gradient LUT ----------

  /// Builds a 256-entry lookup table that lerps across the trail colors.
  /// Index 0 = trail.first, index 255 = trail.last.
  static List<int> _buildLut(List<int> trail, int size) {
    if (trail.isEmpty) {
      return List<int>.filled(size, 0xFFFFFFFF);
    }
    if (trail.length == 1) {
      return List<int>.filled(size, trail.first);
    }
    final out = <int>[];
    for (var i = 0; i < size; i++) {
      final t = i / (size - 1) * (trail.length - 1);
      final lo = t.floor().clamp(0, trail.length - 1);
      final hi = (lo + 1).clamp(0, trail.length - 1);
      final frac = t - lo;
      out.add(_lerpArgb(trail[lo], trail[hi], frac));
    }
    return out;
  }

  static int _lerpArgb(int a, int b, double t) {
    final aA = (a >> 24) & 0xFF;
    final aR = (a >> 16) & 0xFF;
    final aG = (a >> 8) & 0xFF;
    final aB = a & 0xFF;
    final bA = (b >> 24) & 0xFF;
    final bR = (b >> 16) & 0xFF;
    final bG = (b >> 8) & 0xFF;
    final bB = b & 0xFF;
    return ((aA + (bA - aA) * t).round() << 24) |
        ((aR + (bR - aR) * t).round() << 16) |
        ((aG + (bG - aG) * t).round() << 8) |
        (aB + (bB - aB) * t).round();
  }

  // ---------- bloom pass ----------

  /// Adds an asymmetric (radial) soft bloom on top of the rendered points.
  ///
  /// Pipeline:
  ///   1. Downsample 4x (box average) into a low-res buffer.
  ///   2. Two-pass separable Gaussian blur (1x5 horizontal, then 5x1
  ///      vertical) on that low-res buffer for a softer, more natural
  ///      falloff than a single box average.
  ///   3. Up-sample (nearest) back to the full canvas, then composite
  ///      over the source with a position-dependent alpha:
  ///        alpha(x,y) = strength * mask(x,y)
  ///      where
  ///        mask = mix(0.4, 1.0, 1.0 - smoothstep(0.3, 1.0, dist))
  ///      with `dist` = distance from center / min(w,h)/2.
  ///      So the center gets full [strength] and the corners get
  ///      0.4 * strength, with a smooth falloff between 0.3 and 1.0
  ///      of the normalized distance. This kills the "flat halo"
  ///      on dark backgrounds and the "washed-out cloth" on light
  ///      backgrounds — both are symptoms of uniform bloom.
  ///
  /// [strength] is the center alpha (0..1). 0.0 disables the pass.
  /// Recommended: 0.45-0.70.
  static void _applyBloom(
    Uint8List pixels,
    int width,
    int height, {
    int downscale = 4,
    double strength = 0.60,
  }) {
    final dw = (width / downscale).floor();
    final dh = (height / downscale).floor();
    if (dw <= 0 || dh <= 0) return;
    final down = Uint8List(dw * dh * 4);

    // Pass 1: box-average downsample 4x.
    for (var y = 0; y < dh; y++) {
      for (var x = 0; x < dw; x++) {
        var r = 0, g = 0, b = 0;
        var count = 0;
        for (var dy = 0; dy < downscale; dy++) {
          final sy = y * downscale + dy;
          if (sy >= height) break;
          for (var dx = 0; dx < downscale; dx++) {
            final sx = x * downscale + dx;
            if (sx >= width) break;
            final i = (sy * width + sx) * 4;
            r += pixels[i];
            g += pixels[i + 1];
            b += pixels[i + 2];
            count++;
          }
        }
        final j = (y * dw + x) * 4;
        down[j] = (r / count).round();
        down[j + 1] = (g / count).round();
        down[j + 2] = (b / count).round();
        down[j + 3] = 255;
      }
    }

    // Pass 2a: horizontal Gaussian blur (1x5, sigma ~= 1.0).
    // Weights for sigma=1.0: [0.061, 0.245, 0.388, 0.245, 0.061] (sum=1.0).
    final temp = Uint8List(dw * dh * 4);
    for (var y = 0; y < dh; y++) {
      final row = y * dw * 4;
      for (var x = 0; x < dw; x++) {
        double r = 0, g = 0, b = 0;
        // Mirror-clamp the kernel taps at the borders.
        for (var k = -2; k <= 2; k++) {
          final sx = (x + k).clamp(0, dw - 1);
          final i = row + sx * 4;
          final w = _gaussW[k + 2];
          r += down[i] * w;
          g += down[i + 1] * w;
          b += down[i + 2] * w;
        }
        final j = row + x * 4;
        temp[j] = r.round().clamp(0, 255);
        temp[j + 1] = g.round().clamp(0, 255);
        temp[j + 2] = b.round().clamp(0, 255);
        temp[j + 3] = 255;
      }
    }

    // Pass 2b: vertical Gaussian blur (5x1, same weights).
    for (var y = 0; y < dh; y++) {
      for (var x = 0; x < dw; x++) {
        double r = 0, g = 0, b = 0;
        for (var k = -2; k <= 2; k++) {
          final sy = (y + k).clamp(0, dh - 1);
          final i = (sy * dw + x) * 4;
          final w = _gaussW[k + 2];
          r += temp[i] * w;
          g += temp[i + 1] * w;
          b += temp[i + 2] * w;
        }
        final j = (y * dw + x) * 4;
        down[j] = r.round().clamp(0, 255);
        down[j + 1] = g.round().clamp(0, 255);
        down[j + 2] = b.round().clamp(0, 255);
        down[j + 3] = 255;
      }
    }

    // Pre-compute the radial mask once. It is position-dependent but
    // resolution-independent, so we store the alpha multiplier for
    // every (x, y) in the full-res canvas.
    final cx = width / 2.0;
    final cy = height / 2.0;
    final maxDist = math.min(width, height) / 2.0;
    final mask = Float32List(width * height);
    for (var y = 0; y < height; y++) {
      final dy = y - cy;
      final rowBase = y * width;
      for (var x = 0; x < width; x++) {
        final dx = x - cx;
        final dist = math.sqrt(dx * dx + dy * dy) / maxDist;
        // mask = mix(0.4, 1.0, 1.0 - smoothstep(0.3, 1.0, dist))
        //       = 0.4 + 0.6 * (1.0 - smoothstep(0.3, 1.0, dist))
        // At dist <= 0.3: smoothstep = 0  -> mask = 1.0
        // At dist >= 1.0: smoothstep = 1  -> mask = 0.4
        final s = _smoothstep(0.3, 1.0, dist);
        mask[rowBase + x] = 0.4 + 0.6 * (1.0 - s);
      }
    }

    // Composite the blurred low-res back over the source, weighted by
    // the radial mask.
    for (var y = 0; y < height; y++) {
      final sy = (y / downscale).floor().clamp(0, dh - 1);
      final row = y * width * 4;
      final maskRow = y * width;
      for (var x = 0; x < width; x++) {
        final sx = (x / downscale).floor().clamp(0, dw - 1);
        final j = (sy * dw + sx) * 4;
        _blendSrcOver(
          pixels,
          row + x * 4,
          (0xFF << 24) | (down[j] << 16) | (down[j + 1] << 8) | down[j + 2],
          strength * mask[maskRow + x],
        );
      }
    }
  }

  // ---------- premium texture pass (v0.3) ----------

  /// Downsample 2x with a 4-tap bilinear filter, upsample 2x with
  /// bilinear, and blend the result over the source at [mix] alpha.
  ///
  /// Bilinear is the key — nearest-neighbour just resamples the same
  /// dot edges, which is why the v0.2 bloom still looked grainy on
  /// close-up. Bilinear averaging collapses the 1-pixel stipple
  /// alternation into the dominant local colour, which is exactly
  /// what the eye reads as "smooth".
  ///
  /// The original low-frequency signal (the attractor's ribbon shape,
  /// the gradient) survives the round-trip because the downsample
  /// averages a 2x2 block into a single sample. We choose [mix]=0.65
  /// so the smoothed version dominates the high-frequency content
  /// while the original colour still bleeds through, keeping the
  /// image from looking plastic.
  static void _applyBilinearSmooth(
    Uint8List pixels,
    int width,
    int height, {
    double mix = 0.65,
  }) {
    if (mix <= 0) return;
    final dw = width >> 1;
    final dh = height >> 1;
    if (dw <= 0 || dh <= 0) return;

    // --- Pass 1: 2x bilinear downsample into a low-res buffer ---
    // For each low-res pixel (lx, ly) we average the 2x2 source block
    // at (2*lx, 2*ly). This is a centred 2x2 area average — exact
    // bilinear weights would be (0.25, 0.25, 0.25, 0.25).
    final down = Uint8List(dw * dh * 4);
    for (var ly = 0; ly < dh; ly++) {
      final sy0 = ly << 1;
      final sy1 = math.min(sy0 + 1, height - 1);
      final drow = ly * dw * 4;
      for (var lx = 0; lx < dw; lx++) {
        final sx0 = lx << 1;
        final sx1 = math.min(sx0 + 1, width - 1);

        final i00 = (sy0 * width + sx0) * 4;
        final i01 = (sy0 * width + sx1) * 4;
        final i10 = (sy1 * width + sx0) * 4;
        final i11 = (sy1 * width + sx1) * 4;

        final j = drow + lx * 4;
        down[j] = ((pixels[i00] + pixels[i01] + pixels[i10] + pixels[i11]) >> 2)
            .clamp(0, 255);
        down[j + 1] =
            ((pixels[i00 + 1] + pixels[i01 + 1] + pixels[i10 + 1] + pixels[i11 + 1]) >> 2)
                .clamp(0, 255);
        down[j + 2] =
            ((pixels[i00 + 2] + pixels[i01 + 2] + pixels[i10 + 2] + pixels[i11 + 2]) >> 2)
                .clamp(0, 255);
        down[j + 3] = 255;
      }
    }

    // --- Pass 2: 2x bilinear upsample back to full resolution ---
    // For each full-res pixel (x, y) we interpolate between the four
    // surrounding low-res samples with bilinear weights. Pixels on
    // integer 2x boundaries snap to a single sample (no blur on the
    // bbox); in-between pixels blend — that is what kills the grain.
    final out = Uint8List(width * height * 4);
    final invMix = 1.0 - mix;
    for (var y = 0; y < height; y++) {
      final fy = y / 2.0;
      final ly0 = fy.floor().clamp(0, dh - 1);
      final ly1 = math.min(ly0 + 1, dh - 1);
      final wy = fy - ly0;
      final row = y * width * 4;
      for (var x = 0; x < width; x++) {
        final fx = x / 2.0;
        final lx0 = fx.floor().clamp(0, dw - 1);
        final lx1 = math.min(lx0 + 1, dw - 1);
        final wx = fx - lx0;

        final i00 = (ly0 * dw + lx0) * 4;
        final i01 = (ly0 * dw + lx1) * 4;
        final i10 = (ly1 * dw + lx0) * 4;
        final i11 = (ly1 * dw + lx1) * 4;

        // Bilinear weights.
        final w00 = (1 - wy) * (1 - wx);
        final w01 = (1 - wy) * wx;
        final w10 = wy * (1 - wx);
        final w11 = wy * wx;

        for (var c = 0; c < 3; c++) {
          final v = down[i00 + c] * w00 +
              down[i01 + c] * w01 +
              down[i10 + c] * w10 +
              down[i11 + c] * w11;
          out[row + x * 4 + c] = v.round().clamp(0, 255);
        }
        out[row + x * 4 + 3] = 255;
      }
    }

    // --- Pass 3: blend `out` over `pixels` at alpha = mix ---
    // We do this in-place by lerping each channel. The smoothed
    // version dominates so the high-frequency grain is masked, but
    // enough of the original bleeds through to keep the colour
    // identical at the average.
    for (var i = 0; i < pixels.length; i += 4) {
      pixels[i] = (pixels[i] * invMix + out[i] * mix).round().clamp(0, 255);
      pixels[i + 1] =
          (pixels[i + 1] * invMix + out[i + 1] * mix).round().clamp(0, 255);
      pixels[i + 2] =
          (pixels[i + 2] * invMix + out[i + 2] * mix).round().clamp(0, 255);
    }
  }

  /// Adds per-channel film grain on top of the rendered image.
  ///
  /// [intensity] is the maximum channel deviation as a fraction of
  /// 255. 0.02 = ±5 channel-units, which on a 0..255 ramp is ~2% —
  /// visible only as a fine paper-like texture, not as grit. Per-
  /// channel independent noise reads as luminance grain rather than
  /// coloured noise.
  ///
  /// Uses a tiny xorshift PRNG seeded by [seed] so the grain is
  /// deterministic across runs (important for snapshot-style tests
  /// and for keeping the wallpaper visually stable when re-rendered
  /// with the same theme).
  static void _applyFineGrain(
    Uint8List pixels,
    int width,
    int height, {
    double intensity = 0.02,
    int seed = 0xA5F3,
  }) {
    if (intensity <= 0) return;
    final amp = intensity * 255.0;
    var s = seed | 0;
    for (var i = 0; i < pixels.length; i += 4) {
      // xorshift32 — three shifts, no multiply, fast and good enough
      // for a 720x1280 noise field.
      s ^= s << 13;
      s ^= s >> 17;
      s ^= s << 5;
      final n = (s & 0xFFFF) / 0xFFFF - 0.5; // -0.5..0.5
      final delta = (n * amp).round();
      pixels[i] = (pixels[i] + delta).clamp(0, 255);
      pixels[i + 1] = (pixels[i + 1] + delta).clamp(0, 255);
      pixels[i + 2] = (pixels[i + 2] + delta).clamp(0, 255);
    }
  }

  // Gaussian weights for sigma ~= 1.0, 5-tap. Symmetric, sum = 1.0.
  static const List<double> _gaussW = <double>[
    0.061, 0.245, 0.388, 0.245, 0.061,
  ];

  /// GLSL-style smoothstep(edge0, edge1, x) with edge0 < edge1.
  /// Returns 0 below edge0, 1 above edge1, smooth Hermite in between.
  static double _smoothstep(double edge0, double edge1, double x) {
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }

  // ---------- helpers ----------

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

  /// Subtle vignette darkens the edges toward black.
  ///
  /// Alpha curve: 0 inside [safe] (default 0.55) of normalized radius,
  /// ramps to [edgeAlpha] (default 0.85) at the corners via a smoothstep
  /// across [feather] (default 0.40) of normalized distance. The
  /// v0.3 default of 0.85 is the task's "premium" target — visible
  /// framing at the corners without crushing the centre. The wider
  /// [safe] window keeps the bulk of the wallpaper untouched, which
  /// reads as "subtle" in practice even with a strong corner alpha.
  static void _applyVignette(
    Uint8List pixels,
    int width,
    int height, {
    double edgeAlpha = 0.85,
    double safe = 0.55,
    double feather = 0.40,
  }) {
    final cx = width / 2;
    final cy = height / 2;
    final maxDist = math.min(width, height) / 2 * 0.95;

    final startFade = safe;
    final endFade = (safe + feather).clamp(0.0, 1.0);

    for (var y = 0; y < height; y++) {
      final row = y * width * 4;
      final dy = y - cy;
      for (var x = 0; x < width; x++) {
        final dx = x - cx;
        final dist = math.sqrt(dx * dx + dy * dy) / maxDist;
        if (dist <= startFade) continue;
        final t = _smoothstep(startFade, endFade, dist);
        final vignetteAlpha = edgeAlpha * t;
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
