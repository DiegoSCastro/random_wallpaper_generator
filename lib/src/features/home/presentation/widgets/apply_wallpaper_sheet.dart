import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:random_wallpaper_generator/src/core/wallpaper/wallpaper_service.dart';

class ApplyWallpaperSheet extends StatelessWidget {
  const ApplyWallpaperSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isIos = !kIsWeb && Platform.isIOS;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Apply wallpaper',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isIos) ...[
              const SizedBox(height: 8),
              Text(
                'iOS requires using Photos to finish applying the wallpaper.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _TargetTile(
              icon: Icons.home_rounded,
              title: 'Home screen',
              subtitle: isIos ? 'Save and open Share sheet' : 'Set as background',
              onTap: () => Navigator.of(context).pop(WallpaperTarget.homeScreen),
            ),
            _TargetTile(
              icon: Icons.lock_rounded,
              title: 'Lock screen',
              subtitle: isIos ? 'Save and open Share sheet' : 'Set as lock screen',
              onTap: () => Navigator.of(context).pop(WallpaperTarget.lockScreen),
            ),
            _TargetTile(
              icon: Icons.layers_rounded,
              title: 'Both',
              subtitle: isIos ? 'Save and open Share sheet' : 'Set home and lock screen',
              onTap: () => Navigator.of(context).pop(WallpaperTarget.both),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetTile extends StatelessWidget {
  const _TargetTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
      ),
      onTap: onTap,
    );
  }
}
