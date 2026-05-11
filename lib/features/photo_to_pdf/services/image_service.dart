import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

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
    img.Image? originalImage = img.decodeImage(bytes);

    if (originalImage == null) return path;

    img.Image rotatedImage = img.copyRotate(originalImage, angle: angle);

    final tempDir = await getTemporaryDirectory();
    final newPath = '${tempDir.path}/${_uuid.v4()}.jpg';
    final newFile = File(newPath);
    await newFile.writeAsBytes(img.encodeJpg(rotatedImage));

    return newPath;
  }

  static Future<String> applyColorFilter(String path, String filter) async {
    if (filter == 'original' || filter == 'Original') return path;

    final bytes = await File(path).readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);

    if (originalImage == null) return path;

    img.Image filteredImage;
    if (filter == 'grayscale' || filter == 'Grayscale') {
      filteredImage = img.grayscale(originalImage);
    } else if (filter == 'enhanced' || filter == 'Enhanced') {
      filteredImage = img.adjustColor(
        originalImage,
        contrast: 1.2,
        brightness: 1.1,
      );
    } else if (filter == 'Black & White') {
      filteredImage = img.luminanceThreshold(originalImage);
    } else {
      filteredImage = originalImage;
    }

    final tempDir = await getTemporaryDirectory();
    final newPath = '${tempDir.path}/${_uuid.v4()}.jpg';
    final newFile = File(newPath);
    await newFile.writeAsBytes(img.encodeJpg(filteredImage));

    return newPath;
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
    final thumbnails = <Uint8List>[];
    for (final path in paths) {
      try {
        final result = await FlutterImageCompress.compressWithFile(
          path,
          minWidth: 150,
          minHeight: 150,
          quality: 80,
        );
        if (result != null) {
          thumbnails.add(result);
        } else {
          // Fallback or empty if compress fails
          thumbnails.add(Uint8List(0));
        }
      } catch (e) {
        thumbnails.add(Uint8List(0));
      }
    }
    return thumbnails;
  }
}
