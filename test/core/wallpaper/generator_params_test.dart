import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/generators/lorenz.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/generator_params.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_system.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/palette.dart';

void main() {
  group('GeneratorParams.randomized', () {
    test('perturbs Lorenz coefficients away from defaults', () {
      final random = math.Random(42);
      final params = GeneratorParams.randomized(WallpaperSystem.lorenz, random);

      expect(params, isNot(equals(GeneratorParams.lorenzDefault)));
      expect(params.sigma, isNot(GeneratorParams.lorenzDefault.sigma));
      expect(params.rho, isNot(GeneratorParams.lorenzDefault.rho));
      expect(params.seed, isNotNull);
    });

    test('produces visually distinct Lorenz output across regenerations', () {
      const gen = LorenzGenerator();
      const iterations = 5000;

      final first = gen.generate(
        params: GeneratorParams.randomized(
          WallpaperSystem.lorenz,
          math.Random(1),
        ).copyWith(iterations: iterations),
        maxPoints: iterations,
        seed: 1,
      );
      final second = gen.generate(
        params: GeneratorParams.randomized(
          WallpaperSystem.lorenz,
          math.Random(2),
        ).copyWith(iterations: iterations),
        maxPoints: iterations,
        seed: 2,
      );

      var differs = false;
      for (var i = 0; i < iterations; i++) {
        if ((first[i].x - second[i].x).abs() > 1e-6 ||
            (first[i].y - second[i].y).abs() > 1e-6) {
          differs = true;
          break;
        }
      }
      expect(differs, isTrue);
    });
  });

  group('WallpaperPalette.random', () {
    test('returns a palette from the built-in set', () {
      final palette = WallpaperPalette.random(math.Random(7));
      expect(WallpaperPalette.values, contains(palette));
    });
  });
}
