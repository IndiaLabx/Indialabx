import 'dart:io';
import 'dart:typed_data';

import 'package:docsathi/features/photo_to_pdf/presentation/controllers/workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter_image_compress_platform_interface/flutter_image_compress_platform_interface.dart';

import 'package:docsathi/features/photo_to_pdf/services/pdf_service.dart';

class MockFlutterImageCompressPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements FlutterImageCompressPlatform {}

void main() {
  setUpAll(() {
    registerFallbackValue(CompressFormat.jpeg);
  });

  group('PdfService._compressImage', () {
    late MockFlutterImageCompressPlatform mockImageCompressPlatform;
    late File tempFile;
    late String tempPath;
    final fallbackBytes = Uint8List.fromList([1, 2, 3]);

    setUp(() async {
      mockImageCompressPlatform = MockFlutterImageCompressPlatform();
      FlutterImageCompressPlatform.instance = mockImageCompressPlatform;

      // Create a dummy file for the fallback test
      final directory = Directory.systemTemp;
      tempFile = File('${directory.path}/test_image.jpg');
      await tempFile.writeAsBytes(fallbackBytes);
      tempPath = tempFile.path;
    });

    tearDown(() async {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test('CompressionLevel.max uses quality=60 and minWidth=800', () async {
      final expectedBytes = Uint8List.fromList([4, 5, 6]);
      when(
        () => mockImageCompressPlatform.compressWithFile(
          tempPath,
          minWidth: 800,
          minHeight: any(named: 'minHeight'),
          inSampleSize: any(named: 'inSampleSize'),
          quality: 60,
          rotate: any(named: 'rotate'),
          autoCorrectionAngle: any(named: 'autoCorrectionAngle'),
          format: any(named: 'format'),
          keepExif: any(named: 'keepExif'),
          numberOfRetries: any(named: 'numberOfRetries'),
        ),
      ).thenAnswer((_) async => expectedBytes);

      final result = await PdfService.compressImageForTest(
        tempPath,
        CompressionLevel.max,
      );

      expect(result, expectedBytes);
      verify(
        () => mockImageCompressPlatform.compressWithFile(
          tempPath,
          minWidth: 800,
          minHeight: 1080,
          inSampleSize: 1,
          quality: 60,
          rotate: 0,
          autoCorrectionAngle: true,
          format: CompressFormat.jpeg,
          keepExif: false,
          numberOfRetries: 5,
        ),
      ).called(1);
    });

    test(
      'CompressionLevel.balanced uses quality=80 and minWidth=1200',
      () async {
        final expectedBytes = Uint8List.fromList([7, 8, 9]);
        when(
          () => mockImageCompressPlatform.compressWithFile(
            tempPath,
            minWidth: 1200,
            minHeight: any(named: 'minHeight'),
            inSampleSize: any(named: 'inSampleSize'),
            quality: 80,
            rotate: any(named: 'rotate'),
            autoCorrectionAngle: any(named: 'autoCorrectionAngle'),
            format: any(named: 'format'),
            keepExif: any(named: 'keepExif'),
            numberOfRetries: any(named: 'numberOfRetries'),
          ),
        ).thenAnswer((_) async => expectedBytes);

        final result = await PdfService.compressImageForTest(
          tempPath,
          CompressionLevel.balanced,
        );

        expect(result, expectedBytes);
        verify(
          () => mockImageCompressPlatform.compressWithFile(
            tempPath,
            minWidth: 1200,
            minHeight: 1080,
            inSampleSize: 1,
            quality: 80,
            rotate: 0,
            autoCorrectionAngle: true,
            format: CompressFormat.jpeg,
            keepExif: false,
            numberOfRetries: 5,
          ),
        ).called(1);
      },
    );

    test('CompressionLevel.high uses quality=95 and minWidth=2000', () async {
      final expectedBytes = Uint8List.fromList([10, 11, 12]);
      when(
        () => mockImageCompressPlatform.compressWithFile(
          tempPath,
          minWidth: 2000,
          minHeight: any(named: 'minHeight'),
          inSampleSize: any(named: 'inSampleSize'),
          quality: 95,
          rotate: any(named: 'rotate'),
          autoCorrectionAngle: any(named: 'autoCorrectionAngle'),
          format: any(named: 'format'),
          keepExif: any(named: 'keepExif'),
          numberOfRetries: any(named: 'numberOfRetries'),
        ),
      ).thenAnswer((_) async => expectedBytes);

      final result = await PdfService.compressImageForTest(
        tempPath,
        CompressionLevel.high,
      );

      expect(result, expectedBytes);
      verify(
        () => mockImageCompressPlatform.compressWithFile(
          tempPath,
          minWidth: 2000,
          minHeight: 1080,
          inSampleSize: 1,
          quality: 95,
          rotate: 0,
          autoCorrectionAngle: true,
          format: CompressFormat.jpeg,
          keepExif: false,
          numberOfRetries: 5,
        ),
      ).called(1);
    });

    test(
      'falls back to reading file as bytes if compression returns null',
      () async {
        when(
          () => mockImageCompressPlatform.compressWithFile(
            any(),
            minWidth: any(named: 'minWidth'),
            minHeight: any(named: 'minHeight'),
            inSampleSize: any(named: 'inSampleSize'),
            quality: any(named: 'quality'),
            rotate: any(named: 'rotate'),
            autoCorrectionAngle: any(named: 'autoCorrectionAngle'),
            format: any(named: 'format'),
            keepExif: any(named: 'keepExif'),
            numberOfRetries: any(named: 'numberOfRetries'),
          ),
        ).thenAnswer((_) async => null); // Compression failed

        final result = await PdfService.compressImageForTest(
          tempPath,
          CompressionLevel.balanced,
        );

        expect(result, fallbackBytes); // The fallback read the file bytes
      },
    );
  });
}
