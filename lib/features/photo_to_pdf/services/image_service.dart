import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageService {
  static final _uuid = const Uuid();

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
    if (filter == 'Original') return path;

    final bytes = await File(path).readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);

    if (originalImage == null) return path;

    img.Image filteredImage;
    if (filter == 'Grayscale') {
      filteredImage = img.grayscale(originalImage);
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
}
