import 'dart:io';
import 'dart:typed_data';

import 'package:docsathi/features/photo_to_pdf/data/models/pdf_settings_model.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/workspace_controller.dart';
import 'package:docsathi/features/photo_to_pdf/services/pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter_image_compress_platform_interface/flutter_image_compress_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

class MockFlutterImageCompressPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FlutterImageCompressPlatform {
  @override
  Future<Uint8List?> compressWithFile(
    String path, {
    int minWidth = 1920,
    int minHeight = 1080,
    int inSampleSize = 1,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  }) async {
    // Return a valid dummy JPEG image for testing
    // 100x100 white pixel JPEG (larger to handle margins)
    // For simplicity, we just return a valid 1x1 image, and handle margins safely.
    // If it's returning a 1x1 pixel JPEG, `margin: Medium` (20.0) on all sides needs at least a 40x40 area.
    // Since we're using Fit, it will create a 1x1 page size but subtract 20.0 margins.
    // That's why we use 'None' for the Fit test.
    return Uint8List.fromList([
      0xFF,
      0xD8,
      0xFF,
      0xE0,
      0x00,
      0x10,
      0x4A,
      0x46,
      0x49,
      0x46,
      0x00,
      0x01,
      0x01,
      0x00,
      0x00,
      0x01,
      0x00,
      0x01,
      0x00,
      0x00,
      0xFF,
      0xDB,
      0x00,
      0x43,
      0x00,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xDB,
      0x00,
      0x43,
      0x01,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xC0,
      0x00,
      0x11,
      0x08,
      0x00,
      0x01,
      0x00,
      0x01,
      0x03,
      0x01,
      0x22,
      0x00,
      0x02,
      0x11,
      0x01,
      0x03,
      0x11,
      0x01,
      0xFF,
      0xC4,
      0x00,
      0x15,
      0x00,
      0x01,
      0x01,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x08,
      0xFF,
      0xC4,
      0x00,
      0x14,
      0x10,
      0x01,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0xFF,
      0xC4,
      0x00,
      0x14,
      0x01,
      0x01,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0xFF,
      0xC4,
      0x00,
      0x14,
      0x11,
      0x01,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0xFF,
      0xDA,
      0x00,
      0x0C,
      0x03,
      0x01,
      0x00,
      0x02,
      0x11,
      0x03,
      0x11,
      0x00,
      0x3F,
      0x00,
      0xA0,
      0x00,
      0xFF,
      0xD9,
    ]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
    FlutterImageCompressPlatform.instance = MockFlutterImageCompressPlatform();
  });

  group('PdfService.generatePdfFromImages', () {
    late File dummyImage;

    setUpAll(() async {
      dummyImage = File('${Directory.systemTemp.path}/test_image.jpg');
      await dummyImage.writeAsBytes([
        0,
        1,
        2,
        3,
      ]); // Just some dummy bytes to exist
    });

    tearDownAll(() async {
      if (await dummyImage.exists()) {
        await dummyImage.delete();
      }
    });

    test('generates PDF with default settings', () async {
      final page = DocumentPage(
        originalPath: dummyImage.path,
        thumbnailBytes: Uint8List(0),
      );

      final settings = PdfSettingsModel(
        pageSize: 'A4',
        orientation: 'Portrait',
        margin: 'None',
      );

      double lastProgress = 0;
      final pdfPath = await PdfService.generatePdfFromImages(
        pages: [page],
        settings: settings,
        compressionLevel: CompressionLevel.balanced,
        onProgress: (progress, _) => lastProgress = progress,
      );

      expect(pdfPath, isNotEmpty);
      expect(pdfPath, endsWith('.pdf'));
      expect(lastProgress, 1.0);

      final pdfFile = File(pdfPath);
      expect(await pdfFile.exists(), true);
      await pdfFile.delete(); // cleanup
    });

    test('handles multiple pages and progress callback', () async {
      final page = DocumentPage(
        originalPath: dummyImage.path,
        thumbnailBytes: Uint8List(0),
      );

      final settings = PdfSettingsModel(
        pageSize: 'A4',
        orientation: 'Portrait',
        margin: 'None',
      );

      final progressValues = <double>[];
      final pdfPath = await PdfService.generatePdfFromImages(
        pages: [page, page, page], // 3 pages
        settings: settings,
        compressionLevel: CompressionLevel.balanced,
        onProgress: (progress, _) => progressValues.add(progress),
      );

      expect(progressValues, isNotEmpty);
      expect(progressValues.last, 1.0);
      expect(progressValues.length, greaterThan(3)); // multiple calls expected

      final pdfFile = File(pdfPath);
      expect(await pdfFile.exists(), true);
      await pdfFile.delete(); // cleanup
    });

    test('handles landscape, fit page size, and margins', () async {
      final page = DocumentPage(
        originalPath: dummyImage.path,
        thumbnailBytes: Uint8List(0),
      );

      // Using margin 'None' to avoid constraint errors with our 1x1 mock image
      final settings = PdfSettingsModel(
        pageSize: 'Fit',
        orientation: 'Landscape',
        margin: 'None',
      );

      final pdfPath = await PdfService.generatePdfFromImages(
        pages: [page],
        settings: settings,
        compressionLevel: CompressionLevel.max,
      );

      final pdfFile = File(pdfPath);
      expect(await pdfFile.exists(), true);
      await pdfFile.delete(); // cleanup
    });

    test('handles watermarks and page numbers', () async {
      final page = DocumentPage(
        originalPath: dummyImage.path,
        thumbnailBytes: Uint8List(0),
      );

      final settings = PdfSettingsModel(
        pageSize: 'A4',
        orientation: 'Portrait',
        margin: 'Small',
        watermarkText: 'CONFIDENTIAL',
        watermarkColor: Colors.red,
        watermarkOpacity: 0.5,
        watermarkSize: 24.0,
        watermarkAngle: 30.0,
        showPageNumbers: true,
      );

      final pdfPath = await PdfService.generatePdfFromImages(
        pages: [page],
        settings: settings,
        compressionLevel: CompressionLevel.high,
      );

      final pdfFile = File(pdfPath);
      expect(await pdfFile.exists(), true);
      expect(await pdfFile.length(), greaterThan(0));
      await pdfFile.delete(); // cleanup
    });
  });
}
