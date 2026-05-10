import 'package:flutter_test/flutter_test.dart';
import 'package:docsathi/features/photo_to_pdf/services/pdf_service.dart';

void main() {
  group('PdfService Filename Generation', () {
    test('generateOutputFilePath returns a path with DocSathi_ prefix and .pdf extension', () {
      const directoryPath = '/tmp';
      final filePath = PdfService.generateOutputFilePath(directoryPath);

      expect(filePath, startsWith('$directoryPath/DocSathi_'));
      expect(filePath, endsWith('.pdf'));
    });

    test('generateOutputFilePath returns unique filenames using UUID', () {
      const directoryPath = '/tmp';
      final path1 = PdfService.generateOutputFilePath(directoryPath);
      final path2 = PdfService.generateOutputFilePath(directoryPath);

      expect(path1, isNot(equals(path2)));

      // Extract UUID part and verify it looks like a UUID
      final fileName1 = path1.split('/').last;
      final uuidPart = fileName1.replaceFirst('DocSathi_', '').replaceFirst('.pdf', '');

      final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      expect(uuidRegex.hasMatch(uuidPart), isTrue, reason: 'Filename should contain a valid UUID v4');
    });
  });
}
