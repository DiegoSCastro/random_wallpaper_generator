import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:random_wallpaper_generator/src/core/wallpaper/exporter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';

/// Where to apply a wallpaper on the device.
enum WallpaperTarget {
  homeScreen,
  lockScreen,
  both,
}

/// Thrown when the user denies photo library access.
class GalleryAccessDeniedException implements Exception {
  @override
  String toString() => 'Photo library access denied';
}

/// Thrown when setting the wallpaper fails on Android.
class WallpaperApplyException implements Exception {
  WallpaperApplyException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Saves wallpapers to the gallery and applies them to the device.
class WallpaperService {
  const WallpaperService();

  static const galleryAlbum = 'Random Wallpapers';

  Future<void> saveToGallery(ui.Image image) async {
    final bytes = await imageToPngBytes(image);
    await _ensureGalleryAccess();
    await Gal.putImageBytes(
      bytes,
      name: _fileName(),
      album: galleryAlbum,
    );
  }

  Future<WallpaperApplyResult> apply({
    required ui.Image image,
    required WallpaperTarget target,
  }) async {
    final bytes = await imageToPngBytes(image);
    await _ensureGalleryAccess();

    if (!kIsWeb && Platform.isAndroid) {
      final path = await _writeTempFile(bytes);
      try {
        final location = switch (target) {
          WallpaperTarget.homeScreen => WallpaperManagerFlutter.homeScreen,
          WallpaperTarget.lockScreen => WallpaperManagerFlutter.lockScreen,
          WallpaperTarget.both => WallpaperManagerFlutter.bothScreens,
        };
        final manager = WallpaperManagerFlutter();
        final applied = await manager.setWallpaper(File(path), location);
        if (!applied) {
          throw WallpaperApplyException('Could not set wallpaper');
        }
        await Gal.putImageBytes(
          bytes,
          name: _fileName(),
          album: galleryAlbum,
        );
        return WallpaperApplyResult(
          title: _androidApplyTitle(target),
          message: 'Also saved to Photos in "$galleryAlbum".',
        );
      } finally {
        await _deleteIfExists(path);
      }
    }

    if (!kIsWeb && Platform.isIOS) {
      await Gal.putImageBytes(
        bytes,
        name: _fileName(),
        album: galleryAlbum,
      );
      final path = await _writeTempFile(bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'image/png')],
          subject: 'Random Wallpaper',
        ),
      );
      return WallpaperApplyResult(
        title: 'Saved to Photos',
        message: _iosApplyMessage(target),
      );
    }

    throw UnsupportedError('Wallpaper apply is only supported on Android and iOS');
  }

  Future<void> _ensureGalleryAccess() async {
    if (await Gal.hasAccess(toAlbum: true)) return;
    final granted = await Gal.requestAccess(toAlbum: true);
    if (!granted) throw GalleryAccessDeniedException();
  }

  Future<String> _writeTempFile(List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${_fileName()}';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return path;
  }

  Future<void> _deleteIfExists(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } on Exception {
      // best-effort cleanup
    }
  }

  String _fileName() => 'wallpaper_${DateTime.now().millisecondsSinceEpoch}.png';

  String _androidApplyTitle(WallpaperTarget target) {
    return switch (target) {
      WallpaperTarget.homeScreen => 'Home screen wallpaper applied',
      WallpaperTarget.lockScreen => 'Lock screen wallpaper applied',
      WallpaperTarget.both => 'Home and lock screen wallpapers applied',
    };
  }

  String _iosApplyMessage(WallpaperTarget target) {
    final screen = switch (target) {
      WallpaperTarget.homeScreen => 'Home Screen',
      WallpaperTarget.lockScreen => 'Lock Screen',
      WallpaperTarget.both => 'Home and Lock Screen',
    };
    return 'Open Photos, select the image, tap Share, choose '
        '"Use as Wallpaper", then pick $screen.';
  }
}

class WallpaperApplyResult {
  const WallpaperApplyResult({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;
}
