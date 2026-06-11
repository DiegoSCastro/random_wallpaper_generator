import 'models/generator_params.dart';
import 'models/wallpaper_point.dart';
import 'models/wallpaper_system.dart';

/// Pure function that produces a list of normalized points given params.
///
/// Implementations are deterministic for a given [GeneratorParams] (the
/// optional [seed] is used for any random jitter in the renderer, not the
/// dynamical system itself).
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
