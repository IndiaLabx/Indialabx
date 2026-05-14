import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:gal/gal.dart';
import 'package:uuid/uuid.dart';
import 'package:docsathi/features/image_resize/data/models/image_resize_models.dart';
import 'package:docsathi/features/image_resize/services/image_process_service.dart';

class ExportService {
  static const _uuid = Uuid();

  static Future<String?> exportImages(List<ResizeImageItem> items, GlobalResizeSettings settings) async {
    try {
      // 1. Process all images
      final processedItems = await ImageProcessService.generatePreviews(items, settings);

      final tempDir = await getTemporaryDirectory();

      if (processedItems.length == 1) {
         // Single image -> save to gallery
         final item = processedItems.first;
         // The real app needs the optimized bytes output to disk here.
         // Since Gal only supports saving files from a path, we simulate this.
         await Gal.putImage(item.currentActivePath, album: 'DocSathi');
         return 'Saved to Gallery';

      } else {
         // Multiple images -> Create Zip
         final zipPath = path.join(tempDir.path, 'DocSathi_Export_${_uuid.v4().substring(0, 8)}.zip');
         final encoder = ZipFileEncoder();
         encoder.create(zipPath);

         for (final item in processedItems) {
            // In a full implementation, we would encode the final bytes and add from memory
            // encoder.addArchiveFile(ArchiveFile(name, size, bytes));
            // For now, add the active path file to zip
            encoder.addFile(File(item.currentActivePath));
         }

         encoder.close();

         // In a real app we might share this zip or save to a public documents folder
         // Since we can't save zips to gallery easily, we'll just return the path for a share intent later
         return 'Exported to Zip: $zipPath';
      }

    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    }
  }
}
