import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart' show Color;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:docsathi/features/photo_to_pdf/data/models/pdf_settings_model.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

typedef ProgressCallback = void Function(double progress, String message);

class PdfService {
  static final _uuid = const Uuid();

  static String generateOutputFilePath(String directoryPath) {
    return '$directoryPath/DocSathi_${_uuid.v4()}.pdf';
  }

  static PdfColor _getPdfColor(Color color, double opacity) {
    return PdfColor(
      color.r,
      color.g,
      color.b,
      opacity,
    );
  }

  static Future<Uint8List> _compressImage(String path, ImageQuality quality) async {
    if (quality == ImageQuality.original) {
      return await File(path).readAsBytes();
    }

    int qualityVal;
    int targetWidth;
    switch (quality) {
      case ImageQuality.low:
        qualityVal = 60;
        targetWidth = 800;
        break;
      case ImageQuality.medium:
        qualityVal = 80;
        targetWidth = 1200;
        break;
      case ImageQuality.high:
        qualityVal = 95;
        targetWidth = 2000;
        break;
      case ImageQuality.original:
        qualityVal = 100;
        targetWidth = 4000;
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
    required List<String> imagePaths,
    required PdfSettingsModel settings,
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

    final totalImages = imagePaths.length;

    for (int i = 0; i < totalImages; i++) {
      final imagePath = imagePaths[i];

      onProgress?.call((i / totalImages) * 0.8, 'Compressing image ${i + 1} of $totalImages...');

      final imageBytes = await _compressImage(imagePath, settings.imageQuality);
      final image = pw.MemoryImage(imageBytes);

      PdfPageFormat pageFormat = format;
      if (settings.pageSize == 'Fit') {
        pageFormat = PdfPageFormat(image.width!.toDouble(), image.height!.toDouble());
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
                pw.Center(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),

                // Watermark
                if (settings.watermarkText != null && settings.watermarkText!.isNotEmpty)
                  pw.Center(
                    child: pw.Transform.rotate(
                      angle: settings.watermarkAngle * pi / 180,
                      child: pw.Text(
                        settings.watermarkText!,
                        style: pw.TextStyle(
                          color: _getPdfColor(settings.watermarkColor, settings.watermarkOpacity),
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
    final outputFile = File(generateOutputFilePath(outputDir.path));
    await outputFile.writeAsBytes(await pdf.save());

    onProgress?.call(1.0, 'Done!');

    return outputFile.path;
  }
}
