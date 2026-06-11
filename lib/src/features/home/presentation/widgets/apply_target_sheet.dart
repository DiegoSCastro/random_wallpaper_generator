import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:random_wallpaper_generator/src/core/platform/wallpaper_platform.dart';

/// Bottom sheet to pick where to apply the wallpaper: home, lock, or both.
class ApplyTargetSheet extends StatelessWidget {
  const ApplyTargetSheet({super.key});

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
                width: 1,
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
                'Apply Wallpaper',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose where to set it',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              _ApplyTile(
                icon: Icons.home_rounded,
                title: 'Home screen',
                onTap: () =>
                    Navigator.of(context).pop(WallpaperTarget.home),
              ),
              const SizedBox(height: 8),
              _ApplyTile(
                icon: Icons.lock_rounded,
                title: 'Lock screen',
                onTap: () =>
                    Navigator.of(context).pop(WallpaperTarget.lock),
              ),
              const SizedBox(height: 8),
              _ApplyTile(
                icon: Icons.smartphone_rounded,
                title: 'Both',
                onTap: () =>
                    Navigator.of(context).pop(WallpaperTarget.both),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplyTile extends StatelessWidget {
  const _ApplyTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
