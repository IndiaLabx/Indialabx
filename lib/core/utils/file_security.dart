import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileSecurity {
  static Future<bool> isPathSafe(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      final canonicalPath = p.canonicalize(file.absolute.path);

      final docsDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();

      final docsCanonical = p.canonicalize(docsDir.absolute.path);
      final tempCanonical = p.canonicalize(tempDir.absolute.path);

      if (p.isWithin(docsCanonical, canonicalPath) ||
          p.isWithin(tempCanonical, canonicalPath)) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
