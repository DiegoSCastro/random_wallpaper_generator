import 'package:random_wallpaper_generator/src/core/wallpaper/generator.dart' show Generator;

/// Available dynamical systems in v0.1.
///
/// Each system maps to a [Generator] implementation in the registry.
enum WallpaperSystem {
  lorenz('Lorenz', '3D butterfly', 'σ=10, ρ=28, β=8/3'),
  clifford('Clifford', '2D organic', 'a=1.7, b=1.7, c=0.6, d=1.2'),
  hopalong('Hopalong', '2D fractal', 'a=1.0, b=2.0, c=0.0'),
  aizawa('Aizawa', '3D spherical', 'a=0.95, b=0.7, c=0.6, d=3.5, e=0.25, f=0.1'),
  rossler('Rossler', '3D spiral', 'a=0.2, b=0.2, c=5.7'),
  thomas('Thomas', '3D laminar', 'b=0.208186'),
  sprott('Sprott', '3D minimal B', 'a=2.07, b=1.79'),
  halvorsen('Halvorsen', '3D rotational', 'a=1.89'),
  dadras('Dadras', '3D butterfly', 'a=3, b=2.7, c=1.7, d=2, e=9'),
  chen('Chen', '3D twin-lorenz', 'a=40, b=3, c=28'),
  lu('Lü', '3D lorenz-chen', 'a=36, b=3, c=20');

  const WallpaperSystem(this.label, this.shortLabel, this.defaultParamsLabel);

  final String label;
  final String shortLabel;
  final String defaultParamsLabel;

  /// Human-readable system name for UI surfaces (e.g. the home top bar).
  /// Alias of [label] — same value the system picker shows in its list.
  String get displayName => label;

  static WallpaperSystem fromName(String name) =>
      WallpaperSystem.values.firstWhere((s) => s.name == name, orElse: () => WallpaperSystem.lorenz);
}
