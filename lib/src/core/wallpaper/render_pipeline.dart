import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'package:random_wallpaper_generator/src/core/wallpaper/generator.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/generator_params.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/pixel_rasterizer.dart';

/// Runs point generation + CPU rasterization off the UI thread.
class RenderPipeline {
  const RenderPipeline();

  Future<ui.Image> render({
    required Generator generator,
    required GeneratorParams params,
    required List<int> colorsArgb,
    required int width,
    required int height,
  }) async {
    final buffer = await compute(
      _renderInIsolate,
      _RenderJob(
        generator: generator,
        params: params,
        colorsArgb: colorsArgb,
        width: width,
        height: height,
      ),
    );
    return decodePixels(buffer);
  }

  static Future<ui.Image> decodePixels(PixelBuffer buffer) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      buffer.pixels,
      buffer.width,
      buffer.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }
}

class _RenderJob {
  const _RenderJob({
    required this.generator,
    required this.params,
    required this.colorsArgb,
    required this.width,
    required this.height,
  });

  final Generator generator;
  final GeneratorParams params;
  final List<int> colorsArgb;
  final int width;
  final int height;
}

class PixelBuffer {
  const PixelBuffer({
    required this.width,
    required this.height,
    required this.pixels,
  });

  final int width;
  final int height;
  final Uint8List pixels;
}

PixelBuffer _renderInIsolate(_RenderJob job) {
  final points = job.generator.generate(
    params: job.params,
    maxPoints: job.params.iterations,
    seed: job.params.seed,
  );
  final pixels = const PixelRasterizer().rasterize(
    points: points,
    colorsArgb: job.colorsArgb,
    width: job.width,
    height: job.height,
  );
  return PixelBuffer(width: job.width, height: job.height, pixels: pixels);
}
