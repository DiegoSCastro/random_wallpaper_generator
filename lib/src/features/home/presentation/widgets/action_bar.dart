import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:random_wallpaper_generator/src/features/home/presentation/home_cubit.dart';

class ActionBar extends StatelessWidget {
  const ActionBar({
    required this.state,
    required this.onRegenerate,
    required this.onSave,
    required this.onApply,
    required this.onPickSystem,
    super.key,
  });

  final HomeState state;
  final VoidCallback onRegenerate;
  final VoidCallback onSave;
  final VoidCallback onApply;
  final VoidCallback onPickSystem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.45),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _GlassIconButton(
            icon: Icons.refresh_rounded,
            onPressed: state.isGenerating ? null : onRegenerate,
          ),
          _GlassIconButton(icon: Icons.grid_view_rounded, onPressed: onPickSystem),
          _GlassIconButton(
            icon: Icons.download_rounded,
            onPressed: state.isGenerating ? null : onSave,
          ),
          _GlassPrimaryButton(
            icon: Icons.wallpaper_rounded,
            onPressed: state.isGenerating ? null : onApply,
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Material(
          color: Colors.white.withValues(alpha: 0.10),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: onPressed == null ? 0.35 : 1),
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPrimaryButton extends StatelessWidget {
  const _GlassPrimaryButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Material(
          color: Colors.white.withValues(alpha: 0.18),
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: Colors.white.withValues(alpha: onPressed == null ? 0.35 : 1),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Apply',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
