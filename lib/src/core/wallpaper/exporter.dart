import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';

/// Saves a [ui.Image] to a PNG file. Returns the file path.
Future<String> saveImageAsPng(ui.Image image, {String? name}) async {
  final bytes = await imageToPngBytes(image);
  final dir = await getApplicationDocumentsDirectory();
  final fileName = name ?? 'wallpaper_${DateTime.now().millisecondsSinceEpoch}.png';
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<Uint8List> imageToPngBytes(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
