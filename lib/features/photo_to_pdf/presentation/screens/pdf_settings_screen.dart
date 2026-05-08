import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/pdf_settings_controller.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/photo_selection_controller.dart';
import 'package:docsathi/features/photo_to_pdf/services/pdf_service.dart';
import 'package:docsathi/features/photo_to_pdf/data/models/document_model.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/document_controller.dart';
import 'package:uuid/uuid.dart';

class PdfSettingsScreen extends ConsumerStatefulWidget {
  const PdfSettingsScreen({super.key});

  @override
  ConsumerState<PdfSettingsScreen> createState() => _PdfSettingsScreenState();
}

class _PdfSettingsScreenState extends ConsumerState<PdfSettingsScreen> {
  final TextEditingController _fileNameController = TextEditingController();
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _fileNameController.text = 'DocSathi_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> _generatePdf() async {
    final imagePaths = ref.read(photoSelectionProvider);
    if (imagePaths.isEmpty) return;

    final settings = ref.read(pdfSettingsProvider);

    setState(() => _isGenerating = true);

    try {
      final docPath = await PdfService.generatePdfFromImages(
        imagePaths: imagePaths,
        pageSizeStr: settings.pageSize,
        orientationStr: settings.orientation,
        marginStr: settings.margin,
      );

      final docId = const Uuid().v4();
      final document = DocumentModel(
        id: docId,
        filePath: docPath,
        fileName: _fileNameController.text.isEmpty ? 'Document' : _fileNameController.text,
        createdAt: DateTime.now(),
        sizeInBytes: 0, // In a real scenario, get File(docPath).lengthSync()
        pageCount: imagePaths.length,
      );

      await ref.read(documentListProvider.notifier).addDocument(document);

      if (mounted) {
         context.go('/photo-to-pdf/preview', extra: docPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(pdfSettingsProvider);
    final notifier = ref.read(pdfSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('PDF Settings')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _fileNameController,
                  decoration: const InputDecoration(
                    labelText: 'File Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Page Size', style: TextStyle(fontWeight: FontWeight.bold)),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'A4', label: Text('A4')),
                    ButtonSegment(value: 'Letter', label: Text('Letter')),
                    ButtonSegment(value: 'Fit', label: Text('Fit Image')),
                  ],
                  selected: {settings.pageSize},
                  onSelectionChanged: (Set<String> newSelection) {
                    notifier.updateSettings(pageSize: newSelection.first);
                  },
                ),
                const SizedBox(height: 16),

                const Text('Orientation', style: TextStyle(fontWeight: FontWeight.bold)),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Portrait', label: Text('Portrait')),
                    ButtonSegment(value: 'Landscape', label: Text('Landscape')),
                  ],
                  selected: {settings.orientation},
                  onSelectionChanged: (Set<String> newSelection) {
                    notifier.updateSettings(orientation: newSelection.first);
                  },
                ),
                const SizedBox(height: 16),

                const Text('Margin', style: TextStyle(fontWeight: FontWeight.bold)),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'None', label: Text('None')),
                    ButtonSegment(value: 'Small', label: Text('Small')),
                    ButtonSegment(value: 'Medium', label: Text('Medium')),
                  ],
                  selected: {settings.margin},
                  onSelectionChanged: (Set<String> newSelection) {
                    notifier.updateSettings(margin: newSelection.first);
                  },
                ),

                const Spacer(),
                FilledButton.icon(
                  onPressed: _isGenerating ? null : _generatePdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Generate PDF'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          if (_isGenerating)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Generating PDF...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
