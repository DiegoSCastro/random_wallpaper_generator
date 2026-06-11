import 'dart:math' as math;
import 'dart:typed_data';

import '../generator.dart';
import '../models/generator_params.dart';
import '../models/wallpaper_point.dart';
import '../models/wallpaper_system.dart';

/// Martin / Hopalong 2D fractal. Web-like fractal curves.
class HopalongGenerator implements Generator {
  const HopalongGenerator();

  @override
  GeneratorParams get defaultParams => GeneratorParams.hopalongDefault;

  @override
  List<WallpaperPoint> generate({
    required GeneratorParams params,
    required int maxPoints,
    int? seed,
  }) {
    const warmup = 1000;
    final a = params.a, b = params.b, c = params.c;

    var x = 0.0;
    var y = 0.0;
    if (seed != null) {
      final r = math.Random(seed);
      x = (r.nextDouble() - 0.5) * 0.1;
      y = (r.nextDouble() - 0.5) * 0.1;
    }

    for (var i = 0; i < warmup; i++) {
      final t = x;
      final sign = y < 0 ? -1.0 : 1.0;
      x = y - sign * math.sqrt((b * t - c).abs());
      y = a - t;
    }

    final rawX = Float64List(maxPoints);
    final rawY = Float64List(maxPoints);
    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;

    for (var i = 0; i < maxPoints; i++) {
      final t = x;
      final sign = y < 0 ? -1.0 : 1.0;
      x = y - sign * math.sqrt((b * t - c).abs());
      y = a - t;
      rawX[i] = x;
      rawY[i] = y;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    const padding = 0.04;
    final rangeX = (maxX - minX).abs() < 1e-9 ? 1.0 : (maxX - minX);
    final rangeY = (maxY - minY).abs() < 1e-9 ? 1.0 : (maxY - minY);

    final result = List<WallpaperPoint>.filled(maxPoints, const WallpaperPoint(0, 0));
    for (var i = 0; i < maxPoints; i++) {
      final nx = padding + (rawX[i] - minX) / rangeX * (1 - 2 * padding);
      final ny = padding + (rawY[i] - minY) / rangeY * (1 - 2 * padding);
      result[i] = WallpaperPoint(nx, ny);
    }
    return result;
  }
}
