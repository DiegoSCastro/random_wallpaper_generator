// Visual harness — generates one 540x540 preview PNG per WallpaperSystem
// and writes them to assets/system_previews/ so the in-app gallery can
// display them as cached static images (no runtime rasterization).
//
// Run: flutter test test/visual/generate_system_previews.dart --reporter=expanded
//
// Output: assets/system_previews/<system>.png (11 files, 540x540 each)

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/exporter.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/generator_params.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_system.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/palette.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/registry.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/renderer.dart';

void main() {
  test(
    'renders 11 system preview PNGs to assets/system_previews/',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const size = 540;
      const iterations = 200000;

      final outDir = Directory('assets/system_previews');
      if (outDir.existsSync()) outDir.deleteSync(recursive: true);
      outDir.createSync(recursive: true);

      const registry = WallpaperRegistry();
      const renderer = WallpaperRenderer();
      const palette = WallpaperPalette.aurora;

      var count = 0;
      for (final system in WallpaperSystem.values) {
        final params = GeneratorParams.defaultsFor(system).copyWith(
          iterations: iterations,
        );
        final generator = registry.forSystem(system);
        final points = generator.generate(
          params: params,
          maxPoints: iterations,
        );
        final image = await renderer.render(
          points: points,
          palette: palette,
          params: params,
          width: size,
          height: size,
        );
        final bytes = await imageToPngBytes(image);
        final file = File('${outDir.path}/${system.name}.png');
        await file.writeAsBytes(bytes, flush: true);
        image.dispose();
        count++;
        debugPrint('  wrote ${file.path}');
      }
      expect(count, WallpaperSystem.values.length);
      debugPrint('Rendered $count system previews to ${outDir.path}/');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
