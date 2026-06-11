import 'dart:math' as math;
import 'dart:typed_data';

import 'package:random_wallpaper_generator/src/core/wallpaper/generator.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/generator_params.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_point.dart';

/// Chen 3D attractor. Topologically distinct from Lorenz twin family.
///   dx/dt = a*(y - x)
///   dy/dt = (c - a)*x - x*z + c*y
///   dz/dt = x*y - b*z
/// Projects to XY plane.
class ChenGenerator implements Generator {
  const ChenGenerator();

  @override
  GeneratorParams get defaultParams => GeneratorParams.chenDefault;

  @override
  List<WallpaperPoint> generate({
    required GeneratorParams params,
    required int maxPoints,
    int? seed,
  }) {
    const dt = 0.002;
    const warmup = 2000;
    final a = params.a;
    final b = params.b;
    final c = params.c;

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
      x += dt * (a * (y - x));
      y += dt * ((c - a) * x - x * z + c * y);
      z += dt * (x * y - b * z);
    }

    final rawX = Float64List(maxPoints);
    final rawY = Float64List(maxPoints);
    var minX = double.infinity;
    var maxX = -double.infinity;
    var minY = double.infinity;
    var maxY = -double.infinity;

    for (var i = 0; i < maxPoints; i++) {
      x += dt * (a * (y - x));
      y += dt * ((c - a) * x - x * z + c * y);
      z += dt * (x * y - b * z);
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
