import 'package:flutter_test/flutter_test.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/palette.dart';

void main() {
  test('every palette has 4+ colors', () {
    for (final p in WallpaperPalette.values) {
      expect(p.colors().length, greaterThanOrEqualTo(4),
          reason: 'palette ${p.name} should have a gradient');
    }
  });
}
