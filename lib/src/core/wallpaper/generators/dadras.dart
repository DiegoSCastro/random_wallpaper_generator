import 'dart:math' as math;
import 'dart:typed_data';

import 'package:random_wallpaper_generator/src/core/wallpaper/generator.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/generator_params.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_point.dart';

/// Dadras 3D attractor. Butterfly-like multi-scroll structure.
///   dx/dt = y - a*x + b*y*z
///   dy/dt = c*y - x*z + z
///   dz/dt = d*x*y - e*z
/// Projects to XY plane.
class DadrasGenerator implements Generator {
  const DadrasGenerator();

  @override
  GeneratorParams get defaultParams => GeneratorParams.dadrasDefault;

  @override
  List<WallpaperPoint> generate({
    required GeneratorParams params,
    required int maxPoints,
    int? seed,
  }) {
    const dt = 0.005;
    const warmup = 2000;
    final a = params.a;
    final b = params.b;
    final c = params.c;
    final d = params.d;
    final e = params.e;

    var x = 0.1;
    var y = 0.5;
    var z = 0.5;
    if (seed != null) {
      final r = math.Random(seed);
      x = (r.nextDouble() - 0.5) * 0.1;
      y = (r.nextDouble() - 0.5) * 0.1;
      z = (r.nextDouble() - 0.5) * 0.1;
    }

    for (var i = 0; i < warmup; i++) {
      x += dt * (y - a * x + b * y * z);
      y += dt * (c * y - x * z + z);
      z += dt * (d * x * y - e * z);
    }

    final rawX = Float64List(maxPoints);
    final rawY = Float64List(maxPoints);
    var minX = double.infinity;
    var maxX = -double.infinity;
    var minY = double.infinity;
    var maxY = -double.infinity;

    for (var i = 0; i < maxPoints; i++) {
      x += dt * (y - a * x + b * y * z);
      y += dt * (c * y - x * z + z);
      z += dt * (d * x * y - e * z);
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
