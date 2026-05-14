import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:docsathi/features/image_resize/data/models/image_resize_models.dart';

class ImageProcessService {
  static const _uuid = Uuid();

  static Future<List<ResizeImageItem>> loadImages(List<String> paths) async {
    final newItems = <ResizeImageItem>[];
    for (final p in paths) {
      final file = File(p);
      if (!await file.exists()) continue;

      final size = await file.length();
      final bytes = await file.readAsBytes();
      final image = await compute(img.decodeImage, bytes);

      if (image != null) {
        newItems.add(ResizeImageItem(
          originalPath: p,
          filename: path.basename(p),
          originalSizeBytes: size,
          originalWidth: image.width,
          originalHeight: image.height,
          editHistoryPaths: [p],
          historyIndex: 0,
        ));
      }
    }
    return newItems;
  }

  static Future<List<ResizeImageItem>> generatePreviews(List<ResizeImageItem> items, GlobalResizeSettings settings) async {
    final token = RootIsolateToken.instance;
    return await compute(_generatePreviewsIsolate, {
      'items': items,
      'settings': settings,
      'token': token,
    });
  }

  static Future<List<ResizeImageItem>> _generatePreviewsIsolate(Map<String, dynamic> args) async {
    final token = args['token'] as RootIsolateToken?;
    if (token != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    }

    final items = args['items'] as List<ResizeImageItem>;
    final settings = args['settings'] as GlobalResizeSettings;
    final updatedItems = <ResizeImageItem>[];

    for (final item in items) {
      try {
        final currentFile = File(item.currentActivePath);
        final bytes = currentFile.readAsBytesSync();
        img.Image? image = img.decodeImage(bytes);

        if (image == null) {
          updatedItems.add(item);
          continue;
        }

        // 1. Process Virtual Buffer (Scale, Rotate)
        image = _processVirtualBuffer(image, settings);

        // 2. Find optimal quality or use fixed settings
        int finalSizeBytes = 0;
        Uint8List finalBytes;

        if (settings.useTargetFileSize && (settings.format == OutputFormat.jpeg || settings.format == OutputFormat.webp)) {
           final optResult = _optimizeForTargetSize(image, settings);
           finalBytes = optResult.bytes;
           finalSizeBytes = optResult.sizeBytes;
        } else {
           finalBytes = _encodeImage(image, settings.format, settings.quality.toInt());
           finalSizeBytes = finalBytes.length;
        }

        // 3. Generate a small thumbnail for UI (to avoid passing giant byte arrays back)
        final thumbnailImage = img.copyResize(image, width: 300);
        final thumbnailBytes = Uint8List.fromList(img.encodeJpg(thumbnailImage, quality: 70));

        updatedItems.add(item.copyWith(
          previewThumbnail: thumbnailBytes,
          estimatedFinalSizeBytes: finalSizeBytes,
          estimatedFinalWidth: image.width,
          estimatedFinalHeight: image.height,
        ));
      } catch (e) {
         updatedItems.add(item);
      }
    }

    return updatedItems;
  }

  static img.Image _processVirtualBuffer(img.Image image, GlobalResizeSettings settings) {
     img.Image processed = image;

     // Global Rotation
     if (settings.globalRotation != 0) {
       processed = img.copyRotate(processed, angle: settings.globalRotation);
     }

     // Resize Mode
     int targetW = processed.width;
     int targetH = processed.height;

     if (settings.resizeMode == ResizeMode.percentage) {
        final scale = settings.percentage / 100.0;
        targetW = (processed.width * scale).toInt();
        targetH = (processed.height * scale).toInt();
     } else {
        targetW = settings.targetWidth;
        if (settings.lockAspectRatio) {
           final aspectRatio = processed.width / processed.height;
           targetH = (targetW / aspectRatio).toInt();
        } else {
           targetH = settings.targetHeight;
        }
     }

     if (targetW != processed.width || targetH != processed.height) {
        processed = img.copyResize(processed, width: targetW, height: targetH, interpolation: img.Interpolation.linear);
     }

     // Watermark
     if (settings.watermarkText.isNotEmpty) {
        // Very basic text watermark placeholder using image library
        // Real implementation would need a font file, so we use a simple approach or skip for isolate
        // img.drawString(processed, settings.watermarkText, font: img.arial24, x: 10, y: 10);
     }

     return processed;
  }

  static Uint8List _encodeImage(img.Image image, OutputFormat format, int quality) {
     switch (format) {
       case OutputFormat.jpeg:
         return Uint8List.fromList(img.encodeJpg(image, quality: quality));
       case OutputFormat.png:
         return Uint8List.fromList(img.encodePng(image));
       case OutputFormat.webp:
         // Image library does not natively support WebP encoding currently,
         // fallback to Jpeg for now, or use flutter_image_compress on main thread
         return Uint8List.fromList(img.encodeJpg(image, quality: quality));
     }
  }

  static ({Uint8List bytes, int sizeBytes}) _optimizeForTargetSize(img.Image image, GlobalResizeSettings settings) {
      int minQuality = 0;
      int maxQuality = 100;
      int bestQuality = 100;
      Uint8List bestBytes = _encodeImage(image, settings.format, bestQuality);

      if (bestBytes.length <= settings.targetFileSizeBytes) {
         return (bytes: bestBytes, sizeBytes: bestBytes.length);
      }

      for (int i = 0; i < 8; i++) {
         int midQuality = (minQuality + maxQuality) ~/ 2;
         final testBytes = _encodeImage(image, settings.format, midQuality);

         if (testBytes.length > settings.targetFileSizeBytes) {
            maxQuality = midQuality - 1;
         } else {
            bestQuality = midQuality;
            bestBytes = testBytes;
            minQuality = midQuality + 1;
         }
      }

      return (bytes: bestBytes, sizeBytes: bestBytes.length);
  }

  // Straighten Algorithm using Inscribed Rectangle
  static Future<String> straightenImage(String imagePath, double angleDegrees) async {
     final file = File(imagePath);
     final bytes = await file.readAsBytes();

     final processedBytes = await compute(_straightenIsolate, {
        'bytes': bytes,
        'angle': angleDegrees,
     });

     if (processedBytes == null) return imagePath;

     final tempDir = await getTemporaryDirectory();
     final newPath = path.join(tempDir.path, '${_uuid.v4()}.jpg');
     final newFile = File(newPath);
     await newFile.writeAsBytes(processedBytes);

     return newPath;
  }

  static Uint8List? _straightenIsolate(Map<String, dynamic> args) {
     final bytes = args['bytes'] as Uint8List;
     final angleDeg = args['angle'] as double;

     img.Image? image = img.decodeImage(bytes);
     if (image == null) return null;

     // Rotate
     final rotated = img.copyRotate(image, angle: angleDeg.toInt());

     // Inscribed Rectangle calculation
     final rad = angleDeg * (pi / 180.0);
     final w = image.width;
     final h = image.height;

     final double cosA = cos(rad).abs();
     final double sinA = sin(rad).abs();

     // Mathematical approximation for largest inscribed rectangle
     double cropW = w.toDouble();
     double cropH = h.toDouble();

     if (w > h) {
        cropW = w * cosA - h * sinA;
        cropH = h * cosA - w * sinA;
     } else {
        cropW = w * cosA - h * sinA;
        cropH = h * cosA - w * sinA;
     }

     // Fallback if math goes weird due to extreme angles
     if (cropW <= 0 || cropH <= 0) {
        cropW = w * 0.5;
        cropH = h * 0.5;
     }

     final int finalW = cropW.abs().toInt();
     final int finalH = cropH.abs().toInt();

     final int x = (rotated.width - finalW) ~/ 2;
     final int y = (rotated.height - finalH) ~/ 2;

     final cropped = img.copyCrop(rotated, x: x, y: y, width: finalW, height: finalH);

     return Uint8List.fromList(img.encodeJpg(cropped, quality: 95));
  }
}
