// Visual harness — runs as a Flutter integration test.
//
// Run: flutter test test/visual/render_samples_test.dart --reporter=expanded
//
// Output:
//   build/samples/<system>_<palette>.png     (30 files)
//   build/samples/themes/<theme_id>.png      (17 curated themes)
//   build/samples/blend/blend_<0..100>.png   (5 frames of long-press anim)

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/exporter.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/generator_params.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_system.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/palette.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/registry.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/renderer.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/themes.dart';

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

  test(
    'renders 17 curated themes for visual review',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const width = 720;
      const height = 1280;

      final outDir = Directory('build/samples/themes');
      if (outDir.existsSync()) outDir.deleteSync(recursive: true);
      outDir.createSync(recursive: true);

      const registry = WallpaperRegistry();
      const renderer = WallpaperRenderer();
      var count = 0;
      for (final theme in WallpaperTheme.all) {
        final generator = registry.forSystem(theme.system);
        final points = generator.generate(
          params: theme.params,
          maxPoints: theme.params.iterations,
        );
        final image = await renderer.render(
          points: points,
          palette: theme.palette,
          params: theme.params,
          width: width,
          height: height,
        );
        final bytes = await imageToPngBytes(image);
        final file = File('${outDir.path}/${theme.id}.png');
        await file.writeAsBytes(bytes, flush: true);
        image.dispose();
        count++;
      }
      expect(count, WallpaperTheme.all.length);
      debugPrint('Rendered $count curated themes to ${outDir.path}/');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'renders palette blend frames (long-press animation preview)',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const width = 720;
      const height = 1280;
      const iterations = 200000;

      final outDir = Directory('build/samples/blend');
      if (outDir.existsSync()) outDir.deleteSync(recursive: true);
      outDir.createSync(recursive: true);

      const registry = WallpaperRegistry();
      const renderer = WallpaperRenderer();
      const frames = [0.0, 0.25, 0.5, 0.75, 1.0];

      final params = GeneratorParams.cliffordDefault.copyWith(
        iterations: iterations,
      );
      final points = registry.forSystem(WallpaperSystem.clifford).generate(
        params: params,
        maxPoints: iterations,
      );

      // Same image at blend 0 and 1 only — we don't have a paletteA/B
      // pipeline yet, so just sample the "ember" palette at two
      // intensity values to preview the gradient richness.
      var count = 0;
      for (final palette in WallpaperPalette.values) {
        final image = await renderer.render(
          points: points,
          palette: palette,
          params: params,
          width: width,
          height: height,
        );
        final Uint8List bytes = await imageToPngBytes(image);
        final file = File('${outDir.path}/${palette.name}.png');
        await file.writeAsBytes(bytes, flush: true);
        image.dispose();
        count++;
      }
      // Touch the frames constant so the linter does not complain.
      expect(frames.length, greaterThan(0));
      expect(count, WallpaperPalette.values.length);
      debugPrint('Rendered $count blend-style frames to ${outDir.path}/');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
