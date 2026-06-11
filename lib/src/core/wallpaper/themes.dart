import 'package:flutter/material.dart';

import 'package:random_wallpaper_generator/src/core/wallpaper/models/generator_params.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_system.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/palette.dart';

/// A curated, hand-tuned wallpaper preset.
///
/// These exist to make the app feel like a designer picked each one —
/// not a procedural dump. Each theme is a tested combination of system,
/// coefficients, palette, and visual style that consistently produces
/// a good-looking wallpaper.
@immutable
class WallpaperTheme {
  const WallpaperTheme({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.system,
    required this.params,
    required this.palette,
  });

  final String id;
  final String name;
  final String subtitle;
  final WallpaperSystem system;
  final GeneratorParams params;
  final WallpaperPalette palette;

  /// All built-in curated themes.
  ///
  /// Coefficients are tuned to look good with the bundled palette. Each
  /// theme iterates 200k points so the gradient reads cleanly.
  static const all = <WallpaperTheme>[
    // ---------- Clifford (organic, ink-like) ----------
    WallpaperTheme(
      id: 'andromeda',
      name: 'Andromeda',
      subtitle: 'Cosmic dust, cool aurora',
      system: WallpaperSystem.clifford,
      params: GeneratorParams(
        system: WallpaperSystem.clifford,
        a: 1.7,
        b: 1.7,
        c: 0.6,
        d: 1.2,
        iterations: 200000,
        seed: 0,
      ),
      palette: WallpaperPalette.aurora,
    ),
    WallpaperTheme(
      id: 'bioluminescence',
      name: 'Bioluminescence',
      subtitle: 'Deep sea glow, teal',
      system: WallpaperSystem.clifford,
      params: GeneratorParams(
        system: WallpaperSystem.clifford,
        a: -1.4,
        b: 1.6,
        c: 1.0,
        d: 0.7,
        iterations: 200000,
        seed: 0,
      ),
      palette: WallpaperPalette.aurora,
    ),
    WallpaperTheme(
      id: 'obsidian',
      name: 'Obsidian',
      subtitle: 'Black ink on white paper',
      system: WallpaperSystem.clifford,
      params: GeneratorParams(
        system: WallpaperSystem.clifford,
        a: -1.8,
        b: -2.0,
        c: -0.5,
        d: -0.9,
        iterations: 200000,
        seed: 0,
      ),
      palette: WallpaperPalette.mono,
    ),
    WallpaperTheme(
      id: 'crimson-tide',
      name: 'Crimson Tide',
      subtitle: 'Hot ink, red wash',
      system: WallpaperSystem.clifford,
      params: GeneratorParams(
        system: WallpaperSystem.clifford,
        a: 1.5,
        b: -1.8,
        c: 1.8,
        d: -0.7,
        iterations: 200000,
        seed: 0,
      ),
      palette: WallpaperPalette.ember,
    ),

    // ---------- Hopalong (sharp, structural) ----------
    WallpaperTheme(
      id: 'graphite',
      name: 'Graphite',
      subtitle: 'Architectural study',
      system: WallpaperSystem.hopalong,
      params: GeneratorParams(
        system: WallpaperSystem.hopalong,
        a: 0.3,
        b: 0.5,
        c: 4.7,
        d: -0.15,
        iterations: 200000,
        seed: 0,
      ),
      palette: WallpaperPalette.aurora,
    ),
    WallpaperTheme(
      id: 'lava',
      name: 'Lava',
      subtitle: 'Hot ember flow',
      system: WallpaperSystem.hopalong,
      params: GeneratorParams(
        system: WallpaperSystem.hopalong,
        a: 0.7,
        b: 0.4,
        c: 2.7,
        d: 0.1,
        iterations: 200000,
        seed: 0,
      ),
      palette: WallpaperPalette.ember,
    ),
    WallpaperTheme(
      id: 'coral',
      name: 'Coral',
      subtitle: 'Pink reef structure',
      system: WallpaperSystem.hopalong,
      params: GeneratorParams(
        system: WallpaperSystem.hopalong,
        a: -0.9,
        b: 0.5,
        c: 1.5,
        d: -0.3,
        iterations: 200000,
        seed: 0,
      ),
      palette: WallpaperPalette.sakura,
    ),
    WallpaperTheme(
      id: 'plasma',
      name: 'Plasma',
      subtitle: 'Magenta electric arcs',
      system: WallpaperSystem.hopalong,
      params: GeneratorParams(
        system: WallpaperSystem.hopalong,
        a: 0.5,
        b: 0.7,
        c: 3.3,
        d: 0.2,
        iterations: 200000,
        seed: 0,
      ),
      palette: WallpaperPalette.neon,
    ),

    // ---------- Lorenz (smooth, classic) ----------
    WallpaperTheme(
      id: 'tornado',
      name: 'Tornado',
      subtitle: 'Sky-blue vortex',
      system: WallpaperSystem.lorenz,
      params: GeneratorParams(
        system: WallpaperSystem.lorenz,
        sigma: 10,
        rho: 28,
        beta: 8 / 3,
        iterations: 200000,
        seed: 0,
      ),
      palette: WallpaperPalette.ocean,
    ),
    WallpaperTheme(
      id: 'sumi',
      name: 'Sumi',
      subtitle: 'Ink wash, minimal',
      system: WallpaperSystem.lorenz,
      params: GeneratorParams(
        system: WallpaperSystem.lorenz,
        sigma: 10,
        rho: 28,
        beta: 8 / 3,
        iterations: 200000,
        seed: 0,
      ),
      palette: WallpaperPalette.mono,
    ),
    WallpaperTheme(
      id: 'aurora-borealis',
      name: 'Aurora Borealis',
      subtitle: 'Green-blue curtains',
      system: WallpaperSystem.lorenz,
      params: GeneratorParams(
        system: WallpaperSystem.lorenz,
        sigma: 10,
        rho: 28,
        beta: 8 / 3,
        iterations: 200000,
        seed: 0,
      ),
      palette: WallpaperPalette.aurora,
    ),

    // ---------- Aizawa (spherical, structured) ----------
    WallpaperTheme(
      id: 'supernova',
      name: 'Supernova',
      subtitle: 'Magenta burst',
      system: WallpaperSystem.aizawa,
      params: GeneratorParams(
        system: WallpaperSystem.aizawa,
        a: 0.95,
        b: 0.7,
        c: 0.6,
        d: 3.5,
        e: 0.25,
        f: 0.1,
        iterations: 200000,
        seed: 0,
      ),
      palette: WallpaperPalette.neon,
    ),
    WallpaperTheme(
      id: 'rose-quartz',
      name: 'Rose Quartz',
      subtitle: 'Soft pink planetary',
      system: WallpaperSystem.aizawa,
      params: GeneratorParams(
        system: WallpaperSystem.aizawa,
        a: 0.95,
        b: 0.7,
        c: 0.6,
        d: 3.5,
        e: 0.25,
        f: 0.1,
        iterations: 200000,
        seed: 0,
      ),
      palette: WallpaperPalette.sakura,
    ),
    WallpaperTheme(
      id: 'cosmic-dust',
      name: 'Cosmic Dust',
      subtitle: 'Deep aurora sphere',
      system: WallpaperSystem.aizawa,
      params: GeneratorParams(
        system: WallpaperSystem.aizawa,
        a: 0.95,
        b: 0.7,
        c: 0.6,
        d: 3.5,
        e: 0.25,
        f: 0.1,
        iterations: 200000,
        seed: 0,
      ),
      palette: WallpaperPalette.aurora,
    ),

    // ---------- Rossler (organic, wound) ----------
    WallpaperTheme(
      id: 'midnight',
      name: 'Midnight',
      subtitle: 'Cyan-blue tendrils',
      system: WallpaperSystem.rossler,
      params: GeneratorParams(
        system: WallpaperSystem.rossler,
        a: 0.2,
        b: 0.2,
        c: 5.7,
        iterations: 200000,
        seed: 0,
      ),
      palette: WallpaperPalette.ocean,
    ),
    WallpaperTheme(
      id: 'neon-coral',
      name: 'Neon Coral',
      subtitle: 'Vivid magenta vines',
      system: WallpaperSystem.rossler,
      params: GeneratorParams(
        system: WallpaperSystem.rossler,
        a: 0.2,
        b: 0.2,
        c: 5.7,
        iterations: 200000,
        seed: 0,
      ),
      palette: WallpaperPalette.neon,
    ),
    WallpaperTheme(
      id: 'rust',
      name: 'Rust',
      subtitle: 'Worn metal tendrils',
      system: WallpaperSystem.rossler,
      params: GeneratorParams(
        system: WallpaperSystem.rossler,
        a: 0.2,
        b: 0.2,
        c: 5.7,
        iterations: 200000,
        seed: 0,
      ),
      palette: WallpaperPalette.ember,
    ),
  ];

  /// The first theme — used as the initial curated pick.
  static WallpaperTheme get first => all.first;

  /// Look up by id; returns null when not found.
  static WallpaperTheme? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}
