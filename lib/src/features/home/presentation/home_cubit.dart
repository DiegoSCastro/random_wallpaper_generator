import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:random_wallpaper_generator/src/core/wallpaper/exporter.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/generator.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/generator_params.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_point.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_system.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/palette.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/registry.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/renderer.dart';

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
  })  : _registry = registry,
        super(const HomeState(
          status: HomeStatus.initial,
          system: WallpaperSystem.lorenz,
          params: GeneratorParams.lorenzDefault,
          palette: WallpaperPalette.aurora,
        ));

  final WallpaperRegistry _registry;

  Future<void> loadInitial() async {
    await regenerate();
  }

  Future<void> regenerate() async {
    emit(state.copyWith(status: HomeStatus.generating, lastError: null));
    try {
      final generator = _registry.forSystem(state.system);
      final result = await _generate(
        generator: generator,
        params: state.params,
        palette: state.palette,
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
    emit(state.copyWith(
      system: system,
      params: GeneratorParams.defaultsFor(system),
    ));
    await regenerate();
  }

  Future<void> changePalette(WallpaperPalette palette) async {
    emit(state.copyWith(palette: palette));
    await regenerate();
  }

  Future<void> apply(BuildContext context) async {
    if (!state.isReady) return;
    final path = await saveImageAsPng(state.image!);
    if (!context.mounted) return;
    await ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved to $path — apply from your gallery.')),
    );
  }

  Future<void> save(BuildContext context) async {
    if (!state.isReady) return;
    final path = await saveImageAsPng(state.image!);
    if (!context.mounted) return;
    await ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved to $path')),
    );
  }
}

Future<ui.Image> _generate({
  required Generator generator,
  required GeneratorParams params,
  required WallpaperPalette palette,
  required int width,
  required int height,
}) {
  return compute(
    _renderJobIsolate,
    _JobInput(
      generator: generator,
      params: params,
      palette: palette,
      width: width,
      height: height,
    ),
  );
}

class _JobInput {
  const _JobInput({
    required this.generator,
    required this.params,
    required this.palette,
    required this.width,
    required this.height,
  });
  final Generator generator;
  final GeneratorParams params;
  final WallpaperPalette palette;
  final int width;
  final int height;
}

Future<ui.Image> _renderJobIsolate(_JobInput job) async {
  final points = job.generator.generate(
    params: job.params,
    maxPoints: job.params.iterations,
  );
  return const WallpaperRenderer().render(
    points: points,
    palette: job.palette,
    params: job.params,
    width: job.width,
    height: job.height,
  );
}

// Quiet the analyzer for the type that's only re-imported transitively.
// ignore: unused_element
typedef _Unused = WallpaperPoint;
