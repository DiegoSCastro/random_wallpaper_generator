import 'package:flutter_test/flutter_test.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/generators/lorenz.dart';

void main() {
  group('LorenzGenerator', () {
    test('produces 200k points within [0..1] range', () {
      const gen = LorenzGenerator();
      final points = gen.generate(
        params: gen.defaultParams.copyWith(iterations: 200000),
        maxPoints: 200000,
      );
      expect(points.length, 200000);
      for (final p in points) {
        expect(p.x, inInclusiveRange(0.0, 1.0));
        expect(p.y, inInclusiveRange(0.0, 1.0));
      }
    });

    // TODO(v0.2): seed-driven parameter perturbation. Today, the seed only
    // affects the initial condition before warmup; after normalization both
    // runs collapse to the same attractor. Either perturb sigma/rho/beta
    // by a small epsilon derived from the seed, or skip warmup and snap
    // to different sectors of the attractor.
    test('produces deterministic output for the same params (no seed)', () {
      const gen = LorenzGenerator();
      final a = gen.generate(
        params: gen.defaultParams.copyWith(iterations: 1000),
        maxPoints: 1000,
      );
      final b = gen.generate(
        params: gen.defaultParams.copyWith(iterations: 1000),
        maxPoints: 1000,
      );
      for (var i = 0; i < 1000; i++) {
        expect(a[i].x, closeTo(b[i].x, 1e-9));
        expect(a[i].y, closeTo(b[i].y, 1e-9));
      }
    });
  });
}
