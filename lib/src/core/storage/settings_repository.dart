import 'package:fpdart/fpdart.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/models/wallpaper_system.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists user settings (system, palette, quality) in SharedPreferences.
class SettingsRepository {
  SettingsRepository();

  static const _kSystem = 'system';
  static const _kPalette = 'palette';
  static const _kIterations = 'iterations';
  static const _kIsPro = 'is_pro';

  Future<Either<Exception, Unit>> saveSystem(WallpaperSystem system) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSystem, system.name);
      return const Right(unit);
    } on Exception catch (e) {
      return Left(e);
    }
  }

  Future<WallpaperSystem> loadSystem() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_kSystem);
      if (name == null) return WallpaperSystem.lorenz;
      return WallpaperSystem.fromName(name);
    } on Exception catch (_) {
      return WallpaperSystem.lorenz;
    }
  }

  Future<Either<Exception, Unit>> savePalette(WallpaperPalette palette) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPalette, palette.name);
      return const Right(unit);
    } on Exception catch (e) {
      return Left(e);
    }
  }

  Future<WallpaperPalette> loadPalette() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_kPalette);
      if (name == null) return WallpaperPalette.aurora;
      return WallpaperPalette.values.firstWhere(
        (p) => p.name == name,
        orElse: () => WallpaperPalette.aurora,
      );
    } on Exception catch (_) {
      return WallpaperPalette.aurora;
    }
  }

  Future<Either<Exception, Unit>> saveIterations(int iterations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kIterations, iterations);
      return const Right(unit);
    } on Exception catch (e) {
      return Left(e);
    }
  }

  Future<int> loadIterations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_kIterations) ?? 200000;
    } on Exception catch (_) {
      return 200000;
    }
  }

  Future<Either<Exception, Unit>> setPro({required bool isPro}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsPro, isPro);
      return const Right(unit);
    } on Exception catch (e) {
      return Left(e);
    }
  }

  Future<bool> isPro() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kIsPro) ?? false;
    } on Exception catch (_) {
      return false;
    }
  }
}
