import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:docsathi/core/services/permission_service.dart';

class FileService {
  static Future<Directory> getPublicDirectory() async {
    try {
      final hasPermission = await PermissionService.requestStoragePermission();
      if (hasPermission) {
        final dir = Directory('/storage/emulated/0/Download/DocSathi');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return dir;
      }
    } catch (e) {
      // Fallback below
    }
    return await getApplicationDocumentsDirectory();
  }
}
