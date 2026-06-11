import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_system.dart';

/// Tunable parameters for a generator. Each system has its own field set,
/// but the structure is shared so the registry can hold a single type.
class GeneratorParams extends Equatable {
  const GeneratorParams({
    required this.system,
    this.sigma = 10,
    this.rho = 28,
    this.beta = 8 / 3,
    this.a = 1.7,
    this.b = 1.7,
    this.c = 0.6,
    this.d = 1.2,
    this.e = 0.25,
    this.f = 0.1,
    this.iterations = 200000,
    this.seed,
  });

  /// Perturbs system defaults so each regeneration produces a distinct shape.
  factory GeneratorParams.randomized(
    WallpaperSystem system,
    math.Random random, {
    double jitter = 0.22,
  }) {
    final base = defaultsFor(system);
    final seed = random.nextInt(0x7FFFFFFF);

    double vary(double value, {double? amount}) {
      final spread = amount ?? jitter;
      if (value.abs() < 1e-9) {
        return (random.nextDouble() * 2 - 1) * spread;
      }
      return value * (1 + (random.nextDouble() * 2 - 1) * spread);
    }

    switch (system) {
      case WallpaperSystem.lorenz:
        return GeneratorParams(
          system: system,
          sigma: vary(base.sigma, amount: 0.18),
          rho: vary(base.rho, amount: 0.15),
          beta: vary(base.beta, amount: 0.12),
          iterations: base.iterations,
          seed: seed,
        );
      case WallpaperSystem.clifford:
        return GeneratorParams(
          system: system,
          a: vary(base.a),
          b: vary(base.b),
          c: vary(base.c),
          d: vary(base.d),
          iterations: base.iterations,
          seed: seed,
        );
      case WallpaperSystem.hopalong:
        return GeneratorParams(
          system: system,
          a: vary(base.a, amount: 0.35),
          b: vary(base.b, amount: 0.3),
          c: ((random.nextDouble() * 2 - 1) * 0.8).clamp(-1.0, 1.0),
          iterations: base.iterations,
          seed: seed,
        );
      case WallpaperSystem.aizawa:
        return GeneratorParams(
          system: system,
          a: vary(base.a, amount: 0.08),
          b: vary(base.b, amount: 0.12),
          c: vary(base.c),
          d: vary(base.d, amount: 0.12),
          e: vary(base.e, amount: 0.25),
          f: vary(base.f, amount: 0.35),
          iterations: base.iterations,
          seed: seed,
        );
      case WallpaperSystem.rossler:
        return GeneratorParams(
          system: system,
          a: vary(base.a, amount: 0.35),
          b: vary(base.b, amount: 0.35),
          c: vary(base.c, amount: 0.08),
          iterations: base.iterations,
          seed: seed,
        );
    }
  }

  final WallpaperSystem system;
  final double sigma;
  final double rho;
  final double beta;
  final double a;
  final double b;
  final double c;
  final double d;
  final double e;
  final double f;
  final int iterations;
  final int? seed;

  /// Lorenz defaults (σ=10, ρ=28, β=8/3, 200k points).
  static const GeneratorParams lorenzDefault = GeneratorParams(system: WallpaperSystem.lorenz);

  /// Clifford defaults (a=1.7, b=1.7, c=0.6, d=1.2).
  static const GeneratorParams cliffordDefault = GeneratorParams(system: WallpaperSystem.clifford);

  /// Hopalong defaults.
  static const GeneratorParams hopalongDefault = GeneratorParams(
    system: WallpaperSystem.hopalong,
    a: 1,
    b: 2,
    c: 0,
  );

  /// Aizawa defaults.
  static const GeneratorParams aizawaDefault = GeneratorParams(
    system: WallpaperSystem.aizawa,
    a: 0.95,
    b: 0.7,
    d: 3.5,
  );

  /// Rossler defaults.
  static const GeneratorParams rosslerDefault = GeneratorParams(
    system: WallpaperSystem.rossler,
    a: 0.2,
    b: 0.2,
    c: 5.7,
  );

  /// Resolved defaults for a system.
  static GeneratorParams defaultsFor(WallpaperSystem system) {
    switch (system) {
      case WallpaperSystem.lorenz:
        return lorenzDefault;
      case WallpaperSystem.clifford:
        return cliffordDefault;
      case WallpaperSystem.hopalong:
        return hopalongDefault;
      case WallpaperSystem.aizawa:
        return aizawaDefault;
      case WallpaperSystem.rossler:
        return rosslerDefault;
    }
  }

  GeneratorParams copyWith({
    int? iterations,
    int? seed,
  }) {
    return GeneratorParams(
      system: system,
      sigma: sigma,
      rho: rho,
      beta: beta,
      a: a,
      b: b,
      c: c,
      d: d,
      e: e,
      f: f,
      iterations: iterations ?? this.iterations,
      seed: seed ?? this.seed,
    );
  }

  @override
  List<Object?> get props => [system, sigma, rho, beta, a, b, c, d, e, f, iterations, seed];
}
