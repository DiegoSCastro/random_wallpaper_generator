import 'package:flutter/material.dart';

import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_system.dart';

class SystemPickerSheet extends StatelessWidget {
  const SystemPickerSheet({
    required this.current,
    super.key,
  });

  final WallpaperSystem current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pick a system',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            for (final system in WallpaperSystem.values)
              ListTile(
                title: Text(system.label, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  '${system.shortLabel} · ${system.defaultParamsLabel}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: system == current
                    ? const Icon(Icons.check_rounded, color: Colors.white)
                    : null,
                onTap: () => Navigator.of(context).pop(system),
              ),
          ],
        ),
      ),
    );
  }
}
