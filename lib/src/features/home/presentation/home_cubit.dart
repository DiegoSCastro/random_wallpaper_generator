import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:random_wallpaper_generator/src/core/wallpaper/models/generator_params.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_system.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/palette.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/registry.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/render_pipeline.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/themes.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/wallpaper_service.dart';

enum HomeStatus { initial, generating, ready, error }

@immutable
class HomeState extends Equatable {
  const HomeState({
    required this.status,
    required this.system,
    required this.params,
    required this.palette,
    this.image,
    this.lastError,
  });

  final HomeStatus status;
  final WallpaperSystem system;
  final GeneratorParams params;
  final WallpaperPalette palette;
  final ui.Image? image;
  final String? lastError;

  bool get isGenerating => status == HomeStatus.generating;
  bool get isReady => status == HomeStatus.ready && image != null;

  HomeState copyWith({
    HomeStatus? status,
    WallpaperSystem? system,
    GeneratorParams? params,
    WallpaperPalette? palette,
    ui.Image? image,
    String? lastError,
  }) {
    return HomeState(
      status: status ?? this.status,
      system: system ?? this.system,
      params: params ?? this.params,
      palette: palette ?? this.palette,
      image: image ?? this.image,
      lastError: lastError,
    );
  }

  @override
  List<Object?> get props => [status, system, params, palette, image?.width, lastError];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required WallpaperRegistry registry,
    required WallpaperService wallpaperService,
  })  : _registry = registry,
        _wallpaperService = wallpaperService,
        super(const HomeState(
          status: HomeStatus.initial,
          system: WallpaperSystem.lorenz,
          params: GeneratorParams.lorenzDefault,
          palette: WallpaperPalette.aurora,
        ));

  final WallpaperRegistry _registry;
  final WallpaperService _wallpaperService;

  Future<void> loadInitial() async {
    await regenerate();
  }

  Future<void> regenerate({
    bool randomizeParams = true,
    bool randomizePalette = true,
  }) async {
    final random = math.Random();
    final params = randomizeParams
        ? GeneratorParams.randomized(state.system, random)
        : state.params;
    final palette = randomizePalette
        ? WallpaperPalette.random(random)
        : state.palette;

    emit(state.copyWith(
      status: HomeStatus.generating,
      params: params,
      palette: palette,
    ));
    try {
      final generator = _registry.forSystem(state.system);
      final result = await const RenderPipeline().render(
        generator: generator,
        params: params,
        colorsArgb: palette.colors().map((c) => c.toARGB32()).toList(),
        width: 1080,
        height: 1920,
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
    emit(state.copyWith(palette: palette));
    await regenerate(randomizePalette: false);
  }

  /// Apply a curated [WallpaperTheme] — system, params, and palette in
  /// one shot. Bypasses randomization so the result matches the theme's
  /// hand-tuned coefficients exactly.
  Future<void> applyTheme(WallpaperTheme theme) async {
    emit(state.copyWith(
      system: theme.system,
      params: theme.params,
      palette: theme.palette,
    ));
    await regenerate(
      randomizeParams: false,
      randomizePalette: false,
    );
  }

  Future<void> saveToGallery(BuildContext context) async {
    if (!state.isReady) return;
    try {
      await _wallpaperService.saveToGallery(state.image!);
      if (!context.mounted) return;
      _showSnackBar(
        context,
        'Saved to Photos in "${WallpaperService.galleryAlbum}"',
      );
    } on GalleryAccessDeniedException {
      if (!context.mounted) return;
      _showSnackBar(
        context,
        'Allow photo library access in Settings to save wallpapers.',
        isError: true,
      );
    } on Exception catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, 'Could not save: $e', isError: true);
    }
  }

  Future<void> applyWallpaper(
    BuildContext context,
    WallpaperTarget target,
  ) async {
    if (!state.isReady) return;
    try {
      final result = await _wallpaperService.apply(
        image: state.image!,
        target: target,
      );
      if (!context.mounted) return;
      _showSnackBar(context, '${result.title}. ${result.message}');
    } on GalleryAccessDeniedException {
      if (!context.mounted) return;
      _showSnackBar(
        context,
        'Allow photo library access in Settings to apply wallpapers.',
        isError: true,
      );
    } on WallpaperApplyException catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, e.message, isError: true);
    } on Exception catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, 'Could not apply: $e', isError: true);
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final snackBar = isError
        ? SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade800,
          )
        : SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
