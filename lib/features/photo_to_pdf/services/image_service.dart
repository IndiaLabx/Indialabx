import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

class ImageService {
  static final _uuid = const Uuid();

  static Future<Uint8List> generateThumbnail(String path) async {
    final result = await FlutterImageCompress.compressWithFile(
      path,
      minWidth: 150,
      minHeight: 150,
      quality: 80,
    );
    if (result == null) {
      throw Exception("Failed to compress image");
    }
    return result;
  }

  static Future<String> rotateImage(String path, int angle) async {
    final bytes = await File(path).readAsBytes();

    final processedBytes = await compute(_rotateImageIsolate, {
      'bytes': bytes,
      'angle': angle,
    });

    if (processedBytes == null) return path;

    final tempDir = await getTemporaryDirectory();
    final newPath = p.join(tempDir.path, '${_uuid.v4()}.jpg');
    final newFile = File(newPath);
    await newFile.writeAsBytes(processedBytes);

    return newPath;
  }

  static Uint8List? _rotateImageIsolate(Map<String, dynamic> args) {
    final bytes = args['bytes'] as Uint8List;
    final angle = args['angle'] as int;

    img.Image? originalImage = img.decodeImage(bytes);
    if (originalImage == null) return null;

    img.Image rotatedImage = img.copyRotate(originalImage, angle: angle);
    return Uint8List.fromList(img.encodeJpg(rotatedImage));
  }

  static Future<String> applyColorFilter(String path, String filter) async {
    if (filter == 'original' || filter == 'Original') return path;

    final bytes = await File(path).readAsBytes();

    final processedBytes = await compute(_applyFilterIsolate, {
      'bytes': bytes,
      'filter': filter,
    });

    if (processedBytes == null) return path;

    final tempDir = await getTemporaryDirectory();
    final newPath = p.join(tempDir.path, '${_uuid.v4()}.jpg');
    final newFile = File(newPath);
    await newFile.writeAsBytes(processedBytes);

    return newPath;
  }

  static Uint8List? _applyFilterIsolate(Map<String, dynamic> args) {
    final bytes = args['bytes'] as Uint8List;
    final filter = args['filter'] as String;

    img.Image? originalImage = img.decodeImage(bytes);
    if (originalImage == null) return null;

    img.Image filteredImage;
    if (filter == 'grayscale' || filter == 'Grayscale') {
      filteredImage = img.grayscale(originalImage);
    } else if (filter == 'enhanced' || filter == 'Enhanced') {
      filteredImage = img.adjustColor(
        originalImage,
        contrast: 1.2,
        brightness: 1.1,
      );
    } else if (filter == 'magic' || filter == 'Magic') {
      filteredImage = img.adjustColor(
        originalImage,
        contrast: 1.5,
        brightness: 1.2,
      );
    } else if (filter == 'Black & White') {
      filteredImage = img.luminanceThreshold(originalImage);
    } else {
      filteredImage = originalImage;
    }

    return Uint8List.fromList(img.encodeJpg(filteredImage));
  }

  // Isolate processing for generating thumbnails in bulk
  static Future<List<Uint8List>> generateThumbnailsInIsolate(
    List<String> paths,
  ) async {
    final token = RootIsolateToken.instance;
    return await compute(_generateThumbnailsIsolate, {
      'paths': paths,
      'token': token,
    });
  }

  static Future<List<Uint8List>> _generateThumbnailsIsolate(
    Map<String, dynamic> args,
  ) async {
    final token = args['token'] as RootIsolateToken?;
    if (token != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    }
    final paths = args['paths'] as List<String>;
    final futures = paths.map((path) async {
      try {
        final result = await FlutterImageCompress.compressWithFile(
          path,
          minWidth: 150,
          minHeight: 150,
          quality: 80,
        );
        return result ?? Uint8List(0);
      } catch (e) {
        return Uint8List(0);
      }
    });
    return await Future.wait(futures);
  }
}
