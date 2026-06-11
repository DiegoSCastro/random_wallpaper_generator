// Visual harness — runs as a Flutter integration test.
//
// Run: flutter test test/visual/render_samples_test.dart --reporter=expanded
//
// Output: build/samples/<system>_<palette>.png (30 files)

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
    'renders all 30 (system x palette) combinations',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const width = 720;
      const height = 1280;
      const iterations = 200000;

      final outDir = Directory('build/samples');
      if (outDir.existsSync()) outDir.deleteSync(recursive: true);
      outDir.createSync(recursive: true);

      const registry = WallpaperRegistry();
      const renderer = WallpaperRenderer();

      var count = 0;
      for (final system in WallpaperSystem.values) {
        for (final palette in WallpaperPalette.values) {
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
            width: width,
            height: height,
          );
          final bytes = await imageToPngBytes(image);
          final file = File(
            '${outDir.path}/${system.name}_${palette.name}.png',
          );
          await file.writeAsBytes(bytes, flush: true);
          image.dispose();
          count++;
        }
      }
      expect(count, 30);
      debugPrint('Rendered $count samples to ${outDir.path}/');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
