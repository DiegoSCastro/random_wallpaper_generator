package com.omegadev.random_wallpaper_generator

import android.app.WallpaperManager
import android.content.ContentValues
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val wallpaperChannel = "rwg/wallpaper"
    private val galleryChannel = "rwg/gallery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, wallpaperChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "set" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val kind = call.argument<String>("kind") ?: "both"
                        if (bytes == null) {
                            result.error("INVALID_ARGS", "bytes is required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                                ?: throw IllegalStateException("decode failed")
                            val wm = WallpaperManager.getInstance(applicationContext)
                            val flag = when (kind) {
                                "home" -> WallpaperManager.FLAG_SYSTEM
                                "lock" -> WallpaperManager.FLAG_LOCK
                                else -> WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
                            }
                            wm.setBitmap(bitmap, null, true, flag)
                            bitmap.recycle()
                            result.success(mapOf("ok" to true, "kind" to kind))
                        } catch (e: Exception) {
                            result.error("WALLPAPER_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, galleryChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "savePng" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val fileName = call.argument<String>("name")
                            ?: "wallpaper_${System.currentTimeMillis()}.png"
                        if (bytes == null) {
                            result.error("INVALID_ARGS", "bytes is required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val savedPath = saveToGallery(bytes, fileName)
                            result.success(mapOf("ok" to true, "path" to savedPath))
                        } catch (e: Exception) {
                            result.error("GALLERY_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun saveToGallery(bytes: ByteArray, fileName: String): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10+ — MediaStore. No permission needed for own media.
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "image/png")
                put(
                    MediaStore.MediaColumns.RELATIVE_PATH,
                    "${Environment.DIRECTORY_PICTURES}/RandomWallpaper"
                )
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val resolver = contentResolver
            val collection = MediaStore.Images.Media.getContentUri(
                MediaStore.VOLUME_EXTERNAL_PRIMARY
            )
            val uri: Uri = resolver.insert(collection, values)
                ?: throw IllegalStateException("MediaStore.insert returned null")
            resolver.openOutputStream(uri)?.use { os ->
                os.write(bytes)
                os.flush()
            } ?: throw IllegalStateException("openOutputStream returned null")
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            uri.toString()
        } else {
            // Android 9 and below — Pictures/RandomWallpaper dir.
            val picturesDir = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
                "RandomWallpaper"
            )
            if (!picturesDir.exists()) picturesDir.mkdirs()
            val file = File(picturesDir, fileName)
            FileOutputStream(file).use { it.write(bytes) }
            file.absolutePath
        }
    }
}
