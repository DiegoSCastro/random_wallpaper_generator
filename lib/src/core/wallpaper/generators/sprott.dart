import 'dart:math' as math;
import 'dart:typed_data';

import 'package:random_wallpaper_generator/src/core/wallpaper/generator.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/generator_params.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_point.dart';

/// Sprott's 3D quadratic attractor (Sprott 1994). Minimal case B with
/// tunable parameters a=2.07, b=1.79.
///   dx/dt = a*y + y*z
///   dy/dt = 1 - b*x + y*z
///   dz/dt = x - y
/// Projects to XY plane.
class SprottGenerator implements Generator {
  const SprottGenerator();

  @override
  GeneratorParams get defaultParams => GeneratorParams.sprottDefault;

  @override
  List<WallpaperPoint> generate({
    required GeneratorParams params,
    required int maxPoints,
    int? seed,
  }) {
    const dt = 0.01;
    const warmup = 1000;
    final a = params.a;
    final b = params.b;

    var x = 0.1;
    var y = 0.0;
    var z = 0.0;
    if (seed != null) {
      final r = math.Random(seed);
      x = (r.nextDouble() - 0.5) * 0.1;
      y = (r.nextDouble() - 0.5) * 0.1;
      z = (r.nextDouble() - 0.5) * 0.1;
    }

    for (var i = 0; i < warmup; i++) {
      x += dt * (a * y + y * z);
      y += dt * (1 - b * x + y * z);
      z += dt * (x - y);
    }

    final rawX = Float64List(maxPoints);
    final rawY = Float64List(maxPoints);
    var minX = double.infinity;
    var maxX = -double.infinity;
    var minY = double.infinity;
    var maxY = -double.infinity;

    for (var i = 0; i < maxPoints; i++) {
      x += dt * (a * y + y * z);
      y += dt * (1 - b * x + y * z);
      z += dt * (x - y);
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
