import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_system.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/palette.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/registry.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/themes.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/wallpaper_service.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/home_cubit.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/widgets/action_bar.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/widgets/apply_wallpaper_sheet.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/widgets/system_picker_sheet.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/widgets/theme_picker_sheet.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/widgets/wallpaper_canvas.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => HomeCubit(
        registry: ctx.read<WallpaperRegistry>(),
        wallpaperService: ctx.read<WallpaperService>(),
      )..loadInitial(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Random Wallpaper'),
        actions: [
          IconButton(
            icon: const Icon(Icons.collections_bookmark_rounded),
            tooltip: 'Themes',
            onPressed: () => _openThemePicker(context, context.read<HomeCubit>()),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          final cubit = context.read<HomeCubit>();
          return Stack(
            fit: StackFit.expand,
            children: [
              // Tap-and-hold the canvas to re-palette: the cubit re-renders
              // with a different palette on every tap so the wallpaper
              // morphs instantly. Long-press = re-roll palette.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: state.isReady ? () => cubit.changePalette(_nextPalette(state.palette)) : null,
                onLongPress:
                    state.isReady ? () => cubit.changePalette(WallpaperPalette.random()) : null,
                child: WallpaperCanvas(state: state),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: ActionBar(
                    state: state,
                    onRegenerate: cubit.regenerate,
                    onSave: () => cubit.saveToGallery(context),
                    onApply: () => _openApplySheet(context, cubit),
                    onPickSystem: () => _openSystemPicker(context, cubit, state.system),
                  ),
                ),
              ),
              if (state.isGenerating)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openApplySheet(BuildContext context, HomeCubit cubit) async {
    if (!cubit.state.isReady) return;
    final target = await showModalBottomSheet<WallpaperTarget>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const ApplyWallpaperSheet(),
    );
    if (target != null && context.mounted) {
      await cubit.applyWallpaper(context, target);
    }
  }

  Future<void> _openSystemPicker(
    BuildContext context,
    HomeCubit cubit,
    WallpaperSystem current,
  ) async {
    final picked = await showModalBottomSheet<WallpaperSystem>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SystemPickerSheet(
        current: current,
      ),
    );
    if (picked != null) {
      await cubit.changeSystem(picked);
    }
  }

  Future<void> _openThemePicker(BuildContext context, HomeCubit cubit) async {
    final picked = await showModalBottomSheet<WallpaperTheme>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const ThemePickerSheet(),
    );
    if (picked != null) {
      await cubit.applyTheme(picked);
    }
  }

  /// Picks the next palette in the enum, cycling back to the start.
  /// Used by the tap gesture on the canvas so users can cycle palettes
  /// without seeing the same one twice in a row.
  WallpaperPalette _nextPalette(WallpaperPalette current) {
    const values = WallpaperPalette.values;
    final next = (current.index + 1) % values.length;
    return values[next];
  }
}

// WallpaperSystem is used in the picker signature; keep the import alive.
// ignore: unused_element
typedef _Unused = WallpaperSystem;
