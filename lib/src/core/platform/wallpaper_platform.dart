import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Where to apply the wallpaper on Android.
enum WallpaperTarget { home, lock, both }

extension WallpaperTargetCodec on WallpaperTarget {
  String get _kind => switch (this) {
        WallpaperTarget.home => 'home',
        WallpaperTarget.lock => 'lock',
        WallpaperTarget.both => 'both',
      };
}

/// Bridges to the native wallpaper and gallery channels.
///
/// Android: a Kotlin MethodChannel defined in MainActivity.kt. The native
/// side uses [android.app.WallpaperManager.setBitmap] for direct apply
/// and [MediaStore.Images.Media] for gallery save.
///
/// iOS: throws [UnsupportedError] — wallpaper apply from a third-party
/// app is restricted by Apple. Users must use the system "Save image"
/// then apply from Photos. This is an Apple platform constraint, not
/// a missing feature.
class WallpaperPlatform {
  const WallpaperPlatform();

  static const _wallpaper = MethodChannel('rwg/wallpaper');
  static const _gallery = MethodChannel('rwg/gallery');

  /// Apply [image] as the system wallpaper. Returns true on success.
  ///
  /// Throws [PlatformException] if the native call fails.
  Future<bool> apply(ui.Image image, {WallpaperTarget target = WallpaperTarget.both}) async {
    if (Platform.isIOS) {
      throw UnsupportedError(
        'iOS does not allow third-party apps to set the system wallpaper. '
        'Use gallerySave() and apply from Photos.',
      );
    }
    final bytes = await _imageToPngBytes(image);
    final result = await _wallpaper.invokeMethod<Map<dynamic, dynamic>>(
      'set',
      <String, dynamic>{
        'bytes': bytes,
        'kind': target._kind,
      },
    );
    return (result?['ok'] as bool?) ?? false;
  }

  /// Save [image] to the device gallery. Returns the file path or URI.
  ///
  /// On Android 10+ this uses MediaStore (Pictures/RandomWallpaper/).
  /// On Android 9 and below it writes directly to the public Pictures
  /// directory. On iOS this also throws — third-party apps cannot write
  /// to the photo library without permission, which we will request when
  /// the user opts in.
  Future<String> gallerySave(ui.Image image, {String? name}) async {
    if (Platform.isIOS) {
      throw UnsupportedError(
        'iOS gallery save requires photo library permission — implement me.',
      );
    }
    final bytes = await _imageToPngBytes(image);
    final result = await _gallery.invokeMethod<Map<dynamic, dynamic>>(
      'savePng',
      <String, dynamic>{
        'bytes': bytes,
        'name': name,
      },
    );
    return (result?['path'] as String?) ?? '';
  }

  static Future<Uint8List> _imageToPngBytes(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw StateError('toByteData returned null');
    }
    return data.buffer.asUint8List();
  }
}

/// Convenience guard: returns true on Android, false elsewhere.
/// Lets callers UI-gate features that are platform-specific without
/// scattering `if (Platform.isAndroid)` checks.
bool get isAndroid => !kIsWeb && Platform.isAndroid;
bool get isIos => !kIsWeb && Platform.isIOS;
