import 'package:flutter/foundation.dart';

import 'package:random_wallpaper_generator/src/core/wallpaper/generator.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/generators/aizawa.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/generators/chen.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/generators/clifford.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/generators/dadras.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/generators/halvorsen.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/generators/hopalong.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/generators/lorenz.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/generators/lu.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/generators/rossler.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/generators/sprott.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/generators/thomas.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/generator_params.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_system.dart';

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
    WallpaperSystem.thomas: ThomasGenerator(),
    WallpaperSystem.sprott: SprottGenerator(),
    WallpaperSystem.halvorsen: HalvorsenGenerator(),
    WallpaperSystem.dadras: DadrasGenerator(),
    WallpaperSystem.chen: ChenGenerator(),
    WallpaperSystem.lu: LuGenerator(),
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
