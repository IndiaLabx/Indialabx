import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;
import 'package:docsathi/features/photo_to_pdf/data/models/pdf_settings_model.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/workspace_controller.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:docsathi/core/services/file_service.dart';

typedef ProgressCallback = void Function(double progress, String message);

class PdfService {
  static PdfColor _getPdfColor(Color color, double opacity) {
    return PdfColor(color.r, color.g, color.b, opacity);
  }

  static Future<Uint8List> _processSingleImage(Map<String, dynamic> args) async {
    final token = args['token'] as RootIsolateToken?;
    if (token != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    }

    final path = args['path'] as String;
    final filter = args['filter'] as String;
    final compLevel = args['compressionLevel'] as CompressionLevel;

    String pathToProcess = path;
    if (filter != 'original' && filter != 'Original') {
      final bytes = await File(path).readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage != null) {
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

        final tempDir = await getTemporaryDirectory();
        final newPath = p.join(tempDir.path, '${const Uuid().v4()}.jpg');
        final newFile = File(newPath);
        await newFile.writeAsBytes(img.encodeJpg(filteredImage));
        pathToProcess = newPath;
      }
    }

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

    final compressedBytes = await FlutterImageCompress.compressWithFile(
      pathToProcess,
      quality: qualityVal,
      minWidth: targetWidth,
    );

    if (compressedBytes != null) {
      return compressedBytes;
    }
    return await File(pathToProcess).readAsBytes();
  }

  static Future<String> generatePdfFromImages({
    required List<DocumentPage> pages,
    required PdfSettingsModel settings,
    required CompressionLevel compressionLevel,
    ProgressCallback? onProgress,
  }) async {
    pw.Document pdf = pw.Document(compress: true);

    PdfPageFormat format;
    if (settings.pageSize == 'Letter') {
      format = PdfPageFormat.letter;
    } else if (settings.pageSize == 'Fit') {
      format = PdfPageFormat.undefined;
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
    final processedBytesList = List<Uint8List?>.filled(totalImages, null);

    final chunkSize = 3;
    final token = RootIsolateToken.instance;

    for (int i = 0; i < totalImages; i += chunkSize) {
      final end = min(i + chunkSize, totalImages);
      final chunk = pages.sublist(i, end);

      onProgress?.call(
        (i / totalImages) * 0.8,
        'Processing images ${i + 1} to $end of $totalImages...',
      );

      final futures = <Future<Uint8List>>[];
      for (int j = 0; j < chunk.length; j++) {
        futures.add(
          compute(_processSingleImage, {
            'path': chunk[j].effectivePath,
            'filter': chunk[j].filterType.name,
            'compressionLevel': compressionLevel,
            'token': token,
          })
        );
      }

      final results = await Future.wait(futures);
      for (int j = 0; j < results.length; j++) {
        processedBytesList[i + j] = results[j];
      }
    }

    for (int i = 0; i < totalImages; i++) {
      final imageBytes = processedBytesList[i]!;
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

      pw.PageTheme? theme;
      if (settings.pageSize != 'Fit') {
        theme = pw.PageTheme(
          pageFormat: pageFormat.copyWith(
            marginTop: margin,
            marginBottom: margin,
            marginLeft: margin,
            marginRight: margin,
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(
              color: _getPdfColor(settings.backgroundColor, 1.0),
            ),
          ),
        );
      }

      pdf.addPage(
        pw.Page(
          pageFormat: theme == null ? pageFormat.copyWith(
            marginTop: margin,
            marginBottom: margin,
            marginLeft: margin,
            marginRight: margin,
          ) : null,
          pageTheme: theme,
          build: (pw.Context context) {
            return pw.Stack(
              alignment: pw.Alignment.center,
              children: [
                // Background Fill if Smart/Content Aware Fill is selected
                if (settings.imageFit == 'Content Aware Fill' && settings.pageSize != 'Fit')
                  pw.FullPage(
                    ignoreMargins: true,
                    child: pw.Image(image, fit: pw.BoxFit.cover)
                  ),
                if (settings.imageFit == 'Content Aware Fill' && settings.pageSize != 'Fit')
                  pw.FullPage(
                    ignoreMargins: true,
                    child: pw.Container(
                      color: const PdfColor(1, 1, 1, 0.4), // 40% white overlay to simulate blur/fade
                    )
                  ),

                // Main Image
                pw.Center(
                  child: pw.Image(
                    image,
                    fit: settings.imageFit == 'Cover' ? pw.BoxFit.cover : pw.BoxFit.contain
                  )
                ),

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

    final outputDir = await FileService.getPublicDirectory();
    final outputFile = File(
      p.join(outputDir.path, 'DocSathi_${DateTime.now().millisecondsSinceEpoch}.pdf'),
    );
    await outputFile.writeAsBytes(await pdf.save());

    onProgress?.call(1.0, 'Done!');

    return outputFile.path;
  }
}
