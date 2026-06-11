/// Available dynamical systems in v0.1.
///
/// Each system maps to a [Generator] implementation in the registry.
enum WallpaperSystem {
  lorenz('Lorenz', '3D butterfly', 'σ=10, ρ=28, β=8/3'),
  clifford('Clifford', '2D organic', 'a=1.7, b=1.7, c=0.6, d=1.2'),
  hopalong('Hopalong', '2D fractal', 'a=1.0, b=2.0, c=0.0'),
  aizawa('Aizawa', '3D spherical', 'a=0.95, b=0.7, c=0.6, d=3.5, e=0.25, f=0.1'),
  rossler('Rossler', '3D spiral', 'a=0.2, b=0.2, c=5.7');

  const WallpaperSystem(this.label, this.shortLabel, this.defaultParamsLabel);

  final String label;
  final String shortLabel;
  final String defaultParamsLabel;

  static WallpaperSystem fromName(String name) =>
      WallpaperSystem.values.firstWhere((s) => s.name == name, orElse: () => WallpaperSystem.lorenz);
}
