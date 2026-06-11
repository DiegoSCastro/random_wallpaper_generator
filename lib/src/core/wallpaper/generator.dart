import 'package:random_wallpaper_generator/src/core/wallpaper/models/generator_params.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_point.dart';

/// Pure function that produces a list of normalized points given params.
///
/// Implementations are deterministic for a given [GeneratorParams]. The
/// optional seed shifts initial conditions; parameter jitter on regenerate
/// drives distinct attractor shapes.
abstract class Generator {
  GeneratorParams get defaultParams;

  /// Returns the points traced by the system. Caller is responsible for
  /// mapping [0..1] to canvas coordinates. Implementations must be pure
  /// (no I/O, no side-effects) so they can run inside a `compute()` isolate.
  List<WallpaperPoint> generate({
    required GeneratorParams params,
    required int maxPoints,
    int? seed,
  });
}
