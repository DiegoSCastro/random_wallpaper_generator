import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:random_wallpaper_generator/src/core/platform/wallpaper_platform.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_system.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/registry.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/themes.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/home_cubit.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/widgets/action_bar.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/widgets/apply_target_sheet.dart';
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
              // Wallpaper canvas + long-press re-paletting.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPressStart: (_) => cubit.startPaletteAnim(),
                onLongPressEnd: (details) {
                  // Cancel if the user dragged off-target (taps to commit).
                  if (cubit.state.isAnimatingPalette) {
                    cubit.commitPaletteAnim();
                  }
                },
                onTap: () {
                  if (cubit.state.isAnimatingPalette) {
                    cubit.commitPaletteAnim();
                  } else {
                    cubit.startPaletteAnim();
                  }
                },
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
                    onSave: () => _onSave(context, cubit),
                    onApply: () => _onApply(context, cubit),
                    onPickSystem: () => _openSystemPicker(context, cubit, state.system),
                  ),
                ),
              ),
              if (state.isGenerating && state.image == null)
                const Positioned.fill(
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

  Future<void> _onSave(BuildContext context, HomeCubit cubit) async {
    HapticFeedback.selectionClick();
    final result = await cubit.saveToGallery();
    if (!context.mounted) return;
    final msg = result.ok
        ? 'Saved to gallery'
        : result.isUnsupported
            ? 'Gallery not supported on this device'
            : 'Save failed: ${result.error}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _onApply(BuildContext context, HomeCubit cubit) async {
    HapticFeedback.mediumImpact();
    final target = await showModalBottomSheet<WallpaperTarget>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const ApplyTargetSheet(),
    );
    if (target == null) return;
    if (!context.mounted) return;
    final result = await cubit.applyWallpaper(target);
    if (!context.mounted) return;
    final msg = result.ok
        ? 'Wallpaper set!'
        : result.isUnsupported
            ? 'iOS doesn\'t allow direct apply — use Save & set from Photos'
            : 'Apply failed: ${result.error}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _openSystemPicker(
    BuildContext context,
    HomeCubit cubit,
    WallpaperSystem current,
  ) async {
    final picked = await showModalBottomSheet<WallpaperSystem>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SystemPickerSheet(current: current),
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
}
