// Headless visual harness for the wallpaper renderer.
//
// Renders every (system x palette) combination to a PNG so we can review
// visual quality without booting the app. Used during development only.
//
// Run: dart run tool/render_samples.dart
//
// Output: build/samples/<system>_<palette>.png

import 'dart:io';

import 'package:random_wallpaper_generator/src/core/wallpaper/exporter.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/generator_params.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_system.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/palette.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/registry.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/renderer.dart';

Future<void> main() async {
  const width = 720;
  const height = 1280;
  const iterations = 200000;
  final outDir = Directory('build/samples');
  if (outDir.existsSync()) outDir.deleteSync(recursive: true);
  outDir.createSync(recursive: true);

  final registry = const WallpaperRegistry();
  final renderer = const WallpaperRenderer();

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
        palette: palette,
        params: params,
        width: width,
        height: height,
      );
      final bytes = await imageToPngBytes(image);
      final file = File('${outDir.path}/${system.name}_${palette.name}.png');
      await file.writeAsBytes(bytes, flush: true);
      image.dispose();
      count++;
      stdout.write('.');
    }
  }
  stdout.writeln('');
  stdout.writeln('Rendered $count samples to ${outDir.path}/');
}
