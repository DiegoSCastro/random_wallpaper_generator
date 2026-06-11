import 'package:flutter/material.dart';

import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_system.dart';

/// Full-screen gallery for picking a [WallpaperSystem].
///
/// Renders a 2-column grid of previews — one per [WallpaperSystem]. The
/// preview is a static PNG baked at build time by
/// `test/visual/generate_system_previews.dart` and shipped in
/// `assets/system_previews/`, so opening this screen costs ~zero CPU
/// (no runtime rasterization). Tapping a card pops with the chosen
/// system as the result so the caller can apply it via the cubit.
class SystemsGalleryScreen extends StatelessWidget {
  const SystemsGalleryScreen({
    required this.current,
    super.key,
  });

  final WallpaperSystem current;

  /// Path of the baked preview PNG for a given system, relative to the
  /// package root. One file per enum value, generated at build time.
  static String _previewAsset(WallpaperSystem system) =>
      'assets/system_previews/${system.name}.png';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Pick a system'),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: WallpaperSystem.values.length,
          itemBuilder: (context, i) {
            final system = WallpaperSystem.values[i];
            return _SystemCard(
              system: system,
              isCurrent: system == current,
              previewAsset: _previewAsset(system),
              onTap: () => Navigator.of(context).pop(system),
            );
          },
        ),
      ),
    );
  }
}

class _SystemCard extends StatelessWidget {
  const _SystemCard({
    required this.system,
    required this.isCurrent,
    required this.previewAsset,
    required this.onTap,
  });

  final WallpaperSystem system;
  final bool isCurrent;
  final String previewAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isCurrent
        ? Theme.of(context).colorScheme.primary
        : (isDark ? Colors.white24 : Colors.black12);
    final borderWidth = isCurrent ? 2.0 : 1.0;
    final cardColor = isDark ? const Color(0xFF111111) : const Color(0xFFF6F6F6);
    final labelColor = isDark ? Colors.white : Colors.black87;
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: borderWidth),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      previewAsset,
                      fit: BoxFit.cover,
                      cacheWidth: 540,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
              if (isCurrent)
                const Positioned(
                  top: 10,
                  right: 10,
                  child: _CheckPill(),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 18, 10, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  child: Text(
                    system.label,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckPill extends StatelessWidget {
  const _CheckPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_rounded,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}
