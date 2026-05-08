import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

class PdfService {
  static Future<String> generatePdfFromImages({
    required List<String> imagePaths,
    required String pageSizeStr,
    required String orientationStr,
    required String marginStr,
  }) async {
    final pdf = pw.Document();

    PdfPageFormat format;
    if (pageSizeStr == 'Letter') {
      format = PdfPageFormat.letter;
    } else if (pageSizeStr == 'Fit') {
       format = PdfPageFormat.undefined; // We'll handle this per page
    } else {
      format = PdfPageFormat.a4;
    }

    if (pageSizeStr != 'Fit' && orientationStr == 'Landscape') {
      format = format.landscape;
    }

    double margin;
    if (marginStr == 'Small') {
      margin = 10.0;
    } else if (marginStr == 'Medium') {
      margin = 20.0;
    } else {
      margin = 0.0;
    }

    for (final imagePath in imagePaths) {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      PdfPageFormat pageFormat = format;
      if (pageSizeStr == 'Fit') {
         // Create a format that exactly matches the image dimensions (approx)
         // Note: image.width and image.height are available
         pageFormat = PdfPageFormat(image.width!.toDouble(), image.height!.toDouble());
         if (orientationStr == 'Landscape') {
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
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    final outputDir = await getApplicationDocumentsDirectory();
    final outputFile = File('${outputDir.path}/DocSathi_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await outputFile.writeAsBytes(await pdf.save());

    return outputFile.path;
  }
}
