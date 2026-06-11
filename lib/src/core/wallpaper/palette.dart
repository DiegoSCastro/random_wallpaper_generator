import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Built-in palettes. Each is a [List] of colors that the renderer samples
/// along the trajectory (HSL gradient) plus a background.
enum WallpaperPalette {
  aurora('Aurora', 'Green-blue night'),
  ember('Ember', 'Red-orange fire'),
  ocean('Ocean', 'Deep blue-cyan'),
  mono('Mono', 'Black on white'),
  sakura('Sakura', 'Pink and white'),
  neon('Neon', 'Magenta and cyan');

  const WallpaperPalette(this.label, this.description);

  final String label;
  final String description;

  static WallpaperPalette random([math.Random? random]) {
    const values = WallpaperPalette.values;
    final r = random ?? math.Random();
    return values[r.nextInt(values.length)];
  }

  /// Returns the colors for this palette. Index 0 = background, 1.. = trail.
  List<Color> colors() {
    switch (this) {
      case WallpaperPalette.aurora:
        return const [
          Color(0xFF050A18),
          Color(0xFF0F2C5C),
          Color(0xFF1F6FA8),
          Color(0xFF6FE3C2),
          Color(0xFFE6FFB0),
        ];
      case WallpaperPalette.ember:
        return const [
          Color(0xFF120404),
          Color(0xFF460A0A),
          Color(0xFF8A1B0E),
          Color(0xFFE2603A),
          Color(0xFFFFD58A),
        ];
      case WallpaperPalette.ocean:
        return const [
          Color(0xFF001226),
          Color(0xFF062E5C),
          Color(0xFF1B5E9C),
          Color(0xFF3CAFC9),
          Color(0xFFA8E5F0),
        ];
      case WallpaperPalette.mono:
        return const [
          Color(0xFFFFFFFF),
          Color(0xFFD0D0D0),
          Color(0xFF707070),
          Color(0xFF202020),
          Color(0xFF000000),
        ];
      case WallpaperPalette.sakura:
        return const [
          Color(0xFFFFF0F4),
          Color(0xFFFFD1DC),
          Color(0xFFF89BB6),
          Color(0xFFD9688E),
          Color(0xFF7C2C50),
        ];
      case WallpaperPalette.neon:
        return const [
          Color(0xFF0A0014),
          Color(0xFF2A0050),
          Color(0xFF6F00C9),
          Color(0xFFFF1AC6),
          Color(0xFF00F0FF),
        ];
    }
  }
}
