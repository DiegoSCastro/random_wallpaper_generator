import 'dart:ui' as ui;

import 'package:random_wallpaper_generator/src/core/wallpaper/generator.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/generator_params.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_point.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/palette.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/pixel_rasterizer.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/render_pipeline.dart';

/// Renders a list of [WallpaperPoint] into a [ui.Image].
///
/// Prefer [renderAsync] from UI code — it runs generation and rasterization
/// in a background isolate so loaders and animations stay smooth.
class WallpaperRenderer {
  const WallpaperRenderer();

  /// Full off-thread pipeline for interactive use.
  Future<ui.Image> renderAsync({
    required Generator generator,
    required GeneratorParams params,
    required WallpaperPalette palette,
    required int width,
    required int height,
  }) {
    return const RenderPipeline().render(
      generator: generator,
      params: params,
      colorsArgb: _paletteToArgb(palette),
      width: width,
      height: height,
    );
  }

  /// Synchronous generation on the current isolate — for tests and tooling.
  Future<ui.Image> render({
    required List<WallpaperPoint> points,
    required WallpaperPalette palette,
    required GeneratorParams params,
    required int width,
    required int height,
  }) async {
    final pixels = const PixelRasterizer().rasterize(
      points: points,
      colorsArgb: _paletteToArgb(palette),
      width: width,
      height: height,
    );
    return RenderPipeline.decodePixels(
      PixelBuffer(width: width, height: height, pixels: pixels),
    );
  }

  static List<int> _paletteToArgb(WallpaperPalette palette) {
    return palette.colors().map((color) => color.toARGB32()).toList();
  }
}
