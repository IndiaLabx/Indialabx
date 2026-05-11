import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart' show Color;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:docsathi/features/photo_to_pdf/data/models/pdf_settings_model.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/workspace_controller.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:docsathi/features/photo_to_pdf/services/image_service.dart';

typedef ProgressCallback = void Function(double progress, String message);

class PdfService {
  static PdfColor _getPdfColor(Color color, double opacity) {
    return PdfColor(color.r, color.g, color.b, opacity);
  }

  @visibleForTesting
  static Future<Uint8List> compressImageForTest(
    String path,
    CompressionLevel compLevel,
  ) async {
    return _compressImage(path, compLevel);
  }

  static Future<Uint8List> _compressImage(
    String path,
    CompressionLevel compLevel,
  ) async {
    int qualityVal;
    int targetWidth;
    switch (compLevel) {
      case CompressionLevel.max:
        qualityVal = 60;
        targetWidth = 800;
        break;
      case CompressionLevel.balanced:
        qualityVal = 80;
        targetWidth = 1200;
        break;
      case CompressionLevel.high:
        qualityVal = 95;
        targetWidth = 2000;
        break;
    }

    // Read image using flutter_image_compress for efficiency
    final compressedBytes = await FlutterImageCompress.compressWithFile(
      path,
      quality: qualityVal,
      minWidth: targetWidth,
    );

    if (compressedBytes != null) {
      return compressedBytes;
    }

    // Fallback if compress fails
    return await File(path).readAsBytes();
  }

  static Future<String> generatePdfFromImages({
    required List<DocumentPage> pages,
    required PdfSettingsModel settings,
    required CompressionLevel compressionLevel,
    ProgressCallback? onProgress,
  }) async {
    // Current version of `pdf` package doesn't support password protection easily via widgets Document
    // So we'll skip password protection for this step.
    pw.Document pdf = pw.Document(compress: true);

    PdfPageFormat format;
    if (settings.pageSize == 'Letter') {
      format = PdfPageFormat.letter;
    } else if (settings.pageSize == 'Fit') {
      format = PdfPageFormat.undefined; // We'll handle this per page
    } else {
      format = PdfPageFormat.a4;
    }

    if (settings.pageSize != 'Fit' && settings.orientation == 'Landscape') {
      format = format.landscape;
    }

    double margin;
    if (settings.margin == 'Small') {
      margin = 10.0;
    } else if (settings.margin == 'Medium') {
      margin = 20.0;
    } else {
      margin = 0.0;
    }

    final totalImages = pages.length;

    for (int i = 0; i < totalImages; i++) {
      final page = pages[i];

      onProgress?.call(
        (i / totalImages) * 0.8,
        'Processing image ${i + 1} of $totalImages...',
      );

      // 1. Apply Filter (in background isolate via ImageService if needed, but for simplicity here we do it before compress)
      String pathToProcess = page.effectivePath;
      if (page.filterType != FilterType.original) {
        // Apply filter to high-res image and get temp path
        pathToProcess = await ImageService.applyColorFilter(
          pathToProcess,
          page.filterType.name,
        );
      }

      // 2. Compress Image based on Engine Level
      final imageBytes = await _compressImage(pathToProcess, compressionLevel);
      final image = pw.MemoryImage(imageBytes);

      PdfPageFormat pageFormat = format;
      if (settings.pageSize == 'Fit') {
        pageFormat = PdfPageFormat(
          image.width!.toDouble(),
          image.height!.toDouble(),
        );
        if (settings.orientation == 'Landscape') {
          pageFormat = pageFormat.landscape;
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat.copyWith(
            marginTop: margin,
            marginBottom: margin,
            marginLeft: margin,
            marginRight: margin,
          ),
          build: (pw.Context context) {
            return pw.Stack(
              alignment: pw.Alignment.center,
              children: [
                // Main Image
                pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),

                // Watermark
                if (settings.watermarkText != null &&
                    settings.watermarkText!.isNotEmpty)
                  pw.Center(
                    child: pw.Transform.rotate(
                      angle: settings.watermarkAngle * pi / 180,
                      child: pw.Text(
                        settings.watermarkText!,
                        style: pw.TextStyle(
                          color: _getPdfColor(
                            settings.watermarkColor,
                            settings.watermarkOpacity,
                          ),
                          fontSize: settings.watermarkSize,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Page Number
                if (settings.showPageNumbers)
                  pw.Positioned(
                    bottom: 10,
                    child: pw.Text(
                      'Page ${i + 1} of $totalImages',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    onProgress?.call(0.9, 'Saving PDF file...');

    final outputDir = await getApplicationDocumentsDirectory();
    final outputFile = File(
      '${outputDir.path}/DocSathi_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await outputFile.writeAsBytes(await pdf.save());

    onProgress?.call(1.0, 'Done!');

    return outputFile.path;
  }
}
