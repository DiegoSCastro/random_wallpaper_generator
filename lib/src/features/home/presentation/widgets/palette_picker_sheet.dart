import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:random_wallpaper_generator/src/core/wallpaper/palette.dart';

/// Palette picker — bottom sheet that lists every [WallpaperPalette] and
/// returns the picked one to the caller. Mirrors the visual language of
/// ThemePickerSheet (blur + dark glass, drag handle, title + subtitle,
/// rounded list rows) but adds a check indicator on the active palette
/// because this is a mutually-exclusive selector, not a navigation
/// destination.
class PalettePickerSheet extends StatelessWidget {
  const PalettePickerSheet({required this.current, super.key});

  final WallpaperPalette current;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Color Palette',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pick a color palette for the wallpaper',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: WallpaperPalette.values.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final p = WallpaperPalette.values[i];
                    return _PaletteTile(
                      palette: p,
                      selected: p == current,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({required this.palette, required this.selected});
  final WallpaperPalette palette;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = palette.colors();
    // Drop the background color (index 0) — the preview shows the trail
    // gradient that actually paints the wallpaper, not the empty backdrop.
    final trailColors =
        colors.length > 4 ? colors.sublist(colors.length - 4) : colors;
    return Material(
      color: selected
          ? Colors.white.withValues(alpha: 0.14)
          : Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).pop(palette),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: selected
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 1.5,
                  )
                : null,
          ),
          child: Row(
            children: [
              _PaletteSwatch(colors: trailColors),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      palette.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      palette.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 22,
                )
              else
                Icon(
                  Icons.circle_outlined,
                  color: Colors.white.withValues(alpha: 0.35),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({required this.colors});
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}
