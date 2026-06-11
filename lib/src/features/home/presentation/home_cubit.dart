import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:random_wallpaper_generator/src/core/platform/wallpaper_platform.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/generator.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/generator_params.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_system.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/palette.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/registry.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/renderer.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/themes.dart';

enum HomeStatus { initial, generating, ready, error }

@immutable
class HomeState extends Equatable {
  const HomeState({
    required this.status,
    required this.system,
    required this.params,
    required this.paletteA,
    this.paletteB,
    this.blend = 0,
    this.image,
    this.lastError,
  });

  final HomeStatus status;
  final WallpaperSystem system;
  final GeneratorParams params;
  final WallpaperPalette paletteA;

  /// When non-null, the renderer is interpolating from [paletteA] to
  /// [paletteB] by [blend]. When null and blend is 0, the image is
  /// rendered with just [paletteA].
  final WallpaperPalette? paletteB;
  final double blend;
  final ui.Image? image;
  final String? lastError;

  bool get isGenerating => status == HomeStatus.generating;
  bool get isReady => status == HomeStatus.ready && image != null;
  bool get isAnimatingPalette => paletteB != null && blend > 0 && blend < 1;

  /// The palette currently being shown (the dominant end of the blend).
  WallpaperPalette get effectivePalette => paletteB ?? paletteA;

  HomeState copyWith({
    HomeStatus? status,
    WallpaperSystem? system,
    GeneratorParams? params,
    WallpaperPalette? paletteA,
    WallpaperPalette? paletteB,
    double? blend,
    bool clearPaletteB = false,
    ui.Image? image,
    String? lastError,
  }) {
    return HomeState(
      status: status ?? this.status,
      system: system ?? this.system,
      params: params ?? this.params,
      paletteA: paletteA ?? this.paletteA,
      paletteB: clearPaletteB ? null : (paletteB ?? this.paletteB),
      blend: blend ?? this.blend,
      image: image ?? this.image,
      lastError: lastError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        system,
        params,
        paletteA,
        paletteB,
        blend,
        image?.width,
        lastError,
      ];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required WallpaperRegistry registry,
    WallpaperPlatform? platform,
    math.Random? random,
  })  : _registry = registry,
        _platform = platform ?? const WallpaperPlatform(),
        _random = random ?? math.Random(),
        super(HomeState(
          status: HomeStatus.initial,
          system: WallpaperTheme.first.system,
          params: WallpaperTheme.first.params,
          paletteA: WallpaperTheme.first.palette,
        ));

  final WallpaperRegistry _registry;
  final WallpaperPlatform _platform;
  final math.Random _random;

  /// Cached points so re-paletting does not need to re-run the solver.
  List<WallpaperPoint>? _cachedPoints;

  Future<void> loadInitial() async {
    await regenerate();
  }

  Future<void> regenerate({
    bool randomizeParams = true,
    bool randomizePalette = true,
  }) async {
    final params = randomizeParams
        ? GeneratorParams.randomized(state.system, _random)
        : state.params;
    final palette = randomizePalette
        ? WallpaperPalette.random(_random)
        : state.paletteA;

    emit(state.copyWith(
      status: HomeStatus.generating,
      params: params,
      paletteA: palette,
      clearPaletteB: true,
      blend: 0,
    ));
    try {
      final generator = _registry.forSystem(state.system);
      final result = await const RenderPipeline().render(
        generator: generator,
        params: params,
        paletteA: palette,
        paletteB: palette,
        blend: 0,
        width: 1080,
        height: 1920,
        onPointsReady: (p) => _cachedPoints = p,
      );
      emit(state.copyWith(
        status: HomeStatus.ready,
        image: result,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        lastError: e.toString(),
      ));
    }
  }

  Future<void> changeSystem(WallpaperSystem system) async {
    emit(state.copyWith(system: system));
    await regenerate();
  }

  Future<void> changePalette(WallpaperPalette palette) async {
    emit(state.copyWith(paletteA: palette));
    await regenerate(randomizePalette: false);
  }

  /// Apply a curated theme — sets system, params, palette in one shot.
  Future<void> applyTheme(WallpaperTheme theme) async {
    emit(state.copyWith(
      system: theme.system,
      params: theme.params,
      paletteA: theme.palette,
    ));
    await regenerate(randomizeParams: false, randomizePalette: false);
  }

  /// Start a long-press palette animation. The renderer interpolates
  /// from the current [paletteA] to a randomly-chosen [paletteB] over
  /// ~30 frames, then commits by regenerating at the new palette.
  ///
  /// Tapping-and-holding on the canvas should call [startPaletteAnim];
  /// releasing should call [stopPaletteAnim] (or [commitPaletteAnim]).
  Future<void> startPaletteAnim() async {
    if (!state.isReady || _cachedPoints == null) return;
    final candidate = WallpaperPalette.random(_random);
    final b = candidate == state.paletteA
        ? WallpaperPalette.random(_random)
        : candidate;
    emit(state.copyWith(paletteB: b, blend: 0.0));
    await _animateBlend(target: 1.0, frames: 30);
  }

  /// Stop the animation and revert (do not commit). Called if the user
  /// drags off-target.
  Future<void> cancelPaletteAnim() async {
    if (state.paletteB == null) return;
    await _animateBlend(target: 0.0, frames: 12);
    emit(state.copyWith(clearPaletteB: true, blend: 0));
  }

  /// Stop the animation and commit the new palette. Regenerates the
  /// cached points so a subsequent long-press re-palettes from the
  /// newly committed state.
  Future<void> commitPaletteAnim() async {
    if (state.paletteB == null) return;
    await _animateBlend(target: 1.0, frames: 8);
    final newPalette = state.paletteB!;
    emit(state.copyWith(
      paletteA: newPalette,
      clearPaletteB: true,
      blend: 0,
    ));
    // Re-render with the committed palette (no regen of points).
    if (_cachedPoints != null) {
      try {
        final generator = _registry.forSystem(state.system);
        final result = await _generate(
          generator: generator,
          params: state.params,
          paletteA: newPalette,
          paletteB: newPalette,
          blend: 0,
          width: 1080,
          height: 1920,
          onPointsReady: (p) => _cachedPoints = p,
        );
        emit(state.copyWith(image: result));
      } on Exception catch (e) {
        emit(state.copyWith(lastError: e.toString()));
      }
    }
  }

  Future<void> _animateBlend({required double target, required int frames}) async {
    const frameDuration = Duration(milliseconds: 16);
    final start = state.blend;
    for (var i = 1; i <= frames; i++) {
      final t = i / frames;
      final eased = Curves.easeInOutCubic.transform(t);
      final b = start + (target - start) * eased;
      emit(state.copyWith(blend: b.clamp(0.0, 1.0)));
      // Re-render the image at the new blend.
      if (_cachedPoints != null) {
        try {
          final generator = _registry.forSystem(state.system);
          final img = await _generateSync(
            generator: generator,
            params: state.params,
            paletteA: state.paletteA,
            paletteB: state.paletteB ?? state.paletteA,
            blend: b.clamp(0.0, 1.0),
            width: 1080,
            height: 1920,
          );
          emit(state.copyWith(image: img));
        } on Exception catch (_) {
          // Swallow — animation frames shouldn't kill the cubit.
        }
      }
      await Future<void>.delayed(frameDuration);
    }
  }

  /// Apply the current image as the system wallpaper.
  Future<ApplyResult> applyWallpaper(WallpaperTarget target) async {
    if (!state.isReady) {
      return const ApplyResult.failed('No wallpaper ready');
    }
    try {
      await _platform.apply(state.image!, target: target);
      return ApplyResult.success(target);
    } catch (e) {
      // Platform errors and UnsupportedError both surface here.
      final msg = e.toString();
      final isUnsupported = e is UnsupportedError;
      return isUnsupported
          ? ApplyResult.unsupported(msg)
          : ApplyResult.failed(msg);
    }
  }

  /// Save the current image to the device gallery.
  Future<SaveResult> saveToGallery() async {
    if (!state.isReady) {
      return const SaveResult.failed('No wallpaper ready');
    }
    try {
      final path = await _platform.gallerySave(state.image!);
      return SaveResult.success(path);
    } catch (e) {
      final msg = e.toString();
      final isUnsupported = e is UnsupportedError;
      return isUnsupported
          ? SaveResult.unsupported(msg)
          : SaveResult.failed(msg);
    }
  }
}

@immutable
class ApplyResult {
  const ApplyResult._({required this.ok, this.path, this.error, this.unsupportedMsg});
  const ApplyResult.success(WallpaperTarget target) : this._(ok: true);
  const ApplyResult.failed(String msg) : this._(ok: false, error: msg);
  const ApplyResult.unsupported(String msg) : this._(ok: false, unsupportedMsg: msg);

  final bool ok;
  final String? path;
  final String? error;
  final String? unsupportedMsg;
  bool get isUnsupported => unsupportedMsg != null;
}

@immutable
class SaveResult {
  const SaveResult._({required this.ok, this.path, this.error, this.unsupportedMsg});
  const SaveResult.success(String path) : this._(ok: true, path: path);
  const SaveResult.failed(String msg) : this._(ok: false, error: msg);
  const SaveResult.unsupported(String msg) : this._(ok: false, unsupportedMsg: msg);

  final bool ok;
  final String? path;
  final String? error;
  final String? unsupportedMsg;
  bool get isUnsupported => unsupportedMsg != null;
}

Future<ui.Image> _generate({
  required Generator generator,
  required GeneratorParams params,
  required WallpaperPalette paletteA,
  required WallpaperPalette paletteB,
  required double blend,
  required int width,
  required int height,
  void Function(List<WallpaperPoint>)? onPointsReady,
}) async {
  final points = await compute(
    _generatePointsIsolate,
    _PointsJob(generator: generator, params: params),
  );
  if (onPointsReady != null) onPointsReady(points);
  return const WallpaperRenderer().render(
    points: points,
    paletteA: paletteA,
    paletteB: paletteB,
    blend: blend,
    params: params,
    width: width,
    height: height,
  );
}

Future<ui.Image> _generateSync({
  required Generator generator,
  required GeneratorParams params,
  required WallpaperPalette paletteA,
  required WallpaperPalette paletteB,
  required double blend,
  required int width,
  required int height,
}) {
  // We re-run the full generation here because we need fresh points
  // for re-render. The compute isolate is still used.
  return compute(
    _generateRenderedIsolate,
    _RenderJob(
      generator: generator,
      params: params,
      paletteA: paletteA,
      paletteB: paletteB,
      blend: blend,
      width: width,
      height: height,
    ),
  );
}

class _PointsJob {
  const _PointsJob({required this.generator, required this.params});
  final Generator generator;
  final GeneratorParams params;
}

class _RenderJob {
  const _RenderJob({
    required this.generator,
    required this.params,
    required this.paletteA,
    required this.paletteB,
    required this.blend,
    required this.width,
    required this.height,
  });
  final Generator generator;
  final GeneratorParams params;
  final WallpaperPalette paletteA;
  final WallpaperPalette paletteB;
  final double blend;
  final int width;
  final int height;
}

List<WallpaperPoint> _generatePointsIsolate(_PointsJob job) {
  return job.generator.generate(
    params: job.params,
    maxPoints: job.params.iterations,
    seed: job.params.seed,
  );
}

Future<ui.Image> _generateRenderedIsolate(_RenderJob job) async {
  final points = job.generator.generate(
    params: job.params,
    maxPoints: job.params.iterations,
    seed: job.params.seed,
  );
  return const WallpaperRenderer().render(
    points: points,
    paletteA: job.paletteA,
    paletteB: job.paletteB,
    blend: job.blend,
    params: job.params,
    width: job.width,
    height: job.height,
  );
}
