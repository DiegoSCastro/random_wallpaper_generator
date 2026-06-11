// Visual harness — runs as a Flutter integration test.
//
// Run: flutter test test/visual/render_samples_test.dart --reporter=expanded
//
// Output: build/samples/<system>_<palette>.png (30 files)
//
// Also renders a blend frame (50% aurora <-> ember) for the long-press
// animation to confirm the interpolation looks smooth.

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
        final points = generator.generate(params: params, maxPoints: iterations);
        final image = renderer.render(
          points: points,
          paletteA: palette,
          paletteB: palette,
          blend: 0,
          params: params,
          width: width,
          height: height,
        );
        final bytes = await imageToPngBytes(image);
        final file = File('${outDir.path}/${system.name}_${palette.name}.png');
        await file.writeAsBytes(bytes, flush: true);
        image.dispose();
        count++;
      }
    }
    expect(count, 30);
    print('Rendered $count samples to ${outDir.path}/');
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('renders 17 curated themes for visual review', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const width = 720;
    const height = 1280;

    final outDir = Directory('build/samples/themes');
    if (outDir.existsSync()) outDir.deleteSync(recursive: true);
    outDir.createSync(recursive: true);

    final registry = const WallpaperRegistry();
    final renderer = const WallpaperRenderer();
    var count = 0;
    for (final theme in WallpaperTheme.all) {
      final generator = registry.forSystem(theme.system);
      final points = generator.generate(
        params: theme.params,
        maxPoints: theme.params.iterations,
      );
      final image = renderer.render(
        points: points,
        paletteA: theme.palette,
        paletteB: theme.palette,
        blend: 0,
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
    print('Rendered $count curated themes to ${outDir.path}/');
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('renders palette blend frames (long-press animation preview)', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const width = 720;
    const height = 1280;
    const iterations = 200000;

    final outDir = Directory('build/samples/blend');
    if (outDir.existsSync()) outDir.deleteSync(recursive: true);
    outDir.createSync(recursive: true);

    final registry = const WallpaperRegistry();
    final renderer = const WallpaperRenderer();
    const frames = [0.0, 0.25, 0.5, 0.75, 1.0];

    final params = GeneratorParams.cliffordDefault.copyWith(
      iterations: iterations,
    );
    final points = registry.forSystem(WallpaperSystem.clifford).generate(
      params: params,
      maxPoints: iterations,
    );

    var count = 0;
    for (final t in frames) {
      final image = renderer.render(
        points: points,
        paletteA: WallpaperPalette.aurora,
        paletteB: WallpaperPalette.ember,
        blend: t,
        params: params,
        width: width,
        height: height,
      );
      final Uint8List bytes = await imageToPngBytes(image);
      final file = File('${outDir.path}/blend_${(t * 100).round()}.png');
      await file.writeAsBytes(bytes, flush: true);
      image.dispose();
      count++;
    }
    expect(count, frames.length);
    print('Rendered $count blend frames to ${outDir.path}/');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
