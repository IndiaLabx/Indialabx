import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PdfService {
  static Future<String> generatePdfFromImages(List<String> imagePaths) async {
    final pdf = pw.Document();

    for (final imagePath in imagePaths) {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image),
            );
          },
        ),
      );
    }

    final outputDir = await getTemporaryDirectory();
    final outputFile = File('${outputDir.path}/output_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await outputFile.writeAsBytes(await pdf.save());

    return outputFile.path;
  }
}
