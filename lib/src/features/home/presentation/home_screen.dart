import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_system.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/palette.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/registry.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/themes.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/wallpaper_service.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/home_cubit.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/systems_gallery_screen.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/widgets/action_bar.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/widgets/apply_wallpaper_sheet.dart';
import 'package:random_wallpaper_generator/src/features/home/presentation/widgets/palette_picker_sheet.dart';
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
      // No appBar: the top bar is a Positioned overlay inside the Stack so
      // hit tests pass through the empty chrome into the canvas. The user
      // can long-press anywhere on the wallpaper — including the notch /
      // status-bar area — and trigger re-palette. The icon buttons in the
      // top bar still consume their own hit areas.
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
                top: 0,
                child: SafeArea(
                  bottom: false,
                  // Only the icon buttons catch hit tests; the empty chrome
                  // (status-bar / title region) is transparent to gestures
                  // so the canvas receives long-press there.
                  child: _TopBar(
                    systemName: state.system.displayName,
                    onPickPalette: () => _openPalettePicker(context, cubit, state.palette),
                    onPickTheme: () => _openThemePicker(context, cubit),
                    onOpenSettings: () => Navigator.of(context).pushNamed('/settings'),
                  ),
                ),
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
    // Full-screen gallery of static previews — the previews are baked
    // at build time so opening the screen is instant (no runtime
    // rasterization). The cubit applies the picked system on return.
    final picked = await Navigator.of(context).push<WallpaperSystem>(
      MaterialPageRoute(
        builder: (_) => SystemsGalleryScreen(current: current),
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

  Future<void> _openPalettePicker(
    BuildContext context,
    HomeCubit cubit,
    WallpaperPalette current,
  ) async {
    final picked = await showModalBottomSheet<WallpaperPalette>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => PalettePickerSheet(current: current),
    );
    if (picked != null && picked != current) {
      await cubit.changePalette(picked);
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

/// Top bar overlay. Renders the title centered between two icon buttons
/// without a Material under the empty chrome — the empty regions of the
/// bar are transparent to hit tests, so long-press on the canvas reaches
/// the wallpaper even in the status-bar / notch area.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.systemName,
    required this.onPickPalette,
    required this.onPickTheme,
    required this.onOpenSettings,
  });

  final String systemName;
  final VoidCallback onPickPalette;
  final VoidCallback onPickTheme;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          // Leading spacer: balances the trailing 144px icon column so the
          // title sits on the true horizontal center of the screen, not
          // the center of the space between the leading edge and the
          // icons. Hit-test transparent so the canvas still receives
          // long-press in the top-left region.
          const SizedBox(width: 144),
          // Trailing icons — the AppBar usually gives IconButtons a 48px
          // hit area each, so 3 of them need 144px on the right.
          Expanded(
            child: Center(
              // IgnorePointer: title is decorative. If it consumed hits, the
              // canvas's long-press in the status-bar / title region would
              // never fire. The IconButtons below still receive their taps.
              child: IgnorePointer(
                child: Text(
                  systemName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 136,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _LiquidGlassIconButton(
                  icon: Icons.palette_rounded,
                  tooltip: 'Color palette',
                  isDark: isDark,
                  onPressed: onPickPalette,
                ),
                const SizedBox(width: 8),
                _LiquidGlassIconButton(
                  icon: Icons.collections_bookmark_rounded,
                  tooltip: 'Themes',
                  isDark: isDark,
                  onPressed: onPickTheme,
                ),
                const SizedBox(width: 8),
                _LiquidGlassIconButton(
                  icon: Icons.tune_rounded,
                  tooltip: 'Settings',
                  isDark: isDark,
                  onPressed: onOpenSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Liquid-glass icon button used in the top bar.
///
/// Frosted background (`BackdropFilter` + low-alpha tint) so the wallpaper
/// remains visible behind the chrome and the button stays readable on both
/// bright and dark wallpapers. The 1px hairline border further separates
/// the button from the wallpaper without adding a hard edge.
class _LiquidGlassIconButton extends StatelessWidget {
  const _LiquidGlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tint = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.12);
    final iconColor = isDark ? Colors.white : Colors.black;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onPressed,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: iconColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
