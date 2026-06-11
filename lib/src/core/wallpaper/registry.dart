import 'package:flutter/foundation.dart';

import 'generator.dart';
import 'generators/aizawa.dart';
import 'generators/clifford.dart';
import 'generators/hopalong.dart';
import 'generators/lorenz.dart';
import 'generators/rossler.dart';
import 'models/generator_params.dart';
import 'models/wallpaper_system.dart';

/// Maps a [WallpaperSystem] to its [Generator] implementation.
///
/// Adding a new system = new file in `generators/` + 1 line here.
class WallpaperRegistry {
  const WallpaperRegistry();

  static const Map<WallpaperSystem, Generator> _registry = {
    WallpaperSystem.lorenz: LorenzGenerator(),
    WallpaperSystem.clifford: CliffordGenerator(),
    WallpaperSystem.hopalong: HopalongGenerator(),
    WallpaperSystem.aizawa: AizawaGenerator(),
    WallpaperSystem.rossler: RosslerGenerator(),
  };

  Generator forSystem(WallpaperSystem system) {
    final gen = _registry[system];
    if (gen == null) {
      throw StateError('No generator registered for $system');
    }
    return gen;
  }

  List<WallpaperPointCompute> buildComputeJobs({
    required WallpaperSystem system,
    required GeneratorParams params,
    required int iterations,
  }) {
    final generator = forSystem(system);
    return [
      _GeneratorComputeJob(
        generator: generator,
        params: params.copyWith(iterations: iterations),
      ),
    ];
  }
}

/// Marker class for a compute-isolate-friendly job descriptor.
@immutable
class WallpaperPointCompute {
  const WallpaperPointCompute();
}

class _GeneratorComputeJob extends WallpaperPointCompute {
  const _GeneratorComputeJob({required this.generator, required this.params});
  final Generator generator;
  final GeneratorParams params;
}
