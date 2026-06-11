import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the user's saved wallpapers (PNG bytes + metadata).
class FavoritesRepository {
  FavoritesRepository();

  /// Stub: persists a single in-memory key for the MVP.
  /// v0.2: replace with Hive box or path_provider directory.
  Future<Either<Exception, Unit>> savePngBytes(Uint8List bytes, {required String name}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Compress metadata only; bytes are saved to disk in v0.2.
      await prefs.setString('favorite_$name', 'saved_${DateTime.now().millisecondsSinceEpoch}');
      return const Right(unit);
    } catch (e) {
      return Left(e as Exception);
    }
  }

  Future<List<String>> listFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getKeys().where((k) => k.startsWith('favorite_')).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> deleteFavorite(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {
      // best-effort
    }
  }
}
