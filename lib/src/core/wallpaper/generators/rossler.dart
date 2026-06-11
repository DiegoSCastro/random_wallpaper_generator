import 'dart:math' as math;
import 'dart:typed_data';

import '../generator.dart';
import '../models/generator_params.dart';
import '../models/wallpaper_point.dart';
import '../models/wallpaper_system.dart';

/// Rossler 3D attractor. Spiral roll pattern. Projects to XY.
class RosslerGenerator implements Generator {
  const RosslerGenerator();

  @override
  GeneratorParams get defaultParams => GeneratorParams.rosslerDefault;

  @override
  List<WallpaperPoint> generate({
    required GeneratorParams params,
    required int maxPoints,
    int? seed,
  }) {
    const dt = 0.05;
    const warmup = 2000;
    final a = params.a, b = params.b, c = params.c;

    var x = 0.1, y = 0.0, z = 0.0;
    if (seed != null) {
      final r = math.Random(seed);
      x = (r.nextDouble() - 0.5) * 0.1;
      y = (r.nextDouble() - 0.5) * 0.1;
      z = (r.nextDouble() - 0.5) * 0.1;
    }

    for (var i = 0; i < warmup; i++) {
      x += dt * (-y - z);
      y += dt * (x + a * y);
      z += dt * (b + z * (x - c));
    }

    final rawX = Float64List(maxPoints);
    final rawY = Float64List(maxPoints);
    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;

    for (var i = 0; i < maxPoints; i++) {
      x += dt * (-y - z);
      y += dt * (x + a * y);
      z += dt * (b + z * (x - c));
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
