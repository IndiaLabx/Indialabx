import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:docsathi/features/photo_to_pdf/presentation/controllers/pdf_settings_controller.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/workspace_controller.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/document_controller.dart';
import 'package:docsathi/features/photo_to_pdf/data/models/document_model.dart';
import 'package:docsathi/features/photo_to_pdf/services/pdf_service.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/screens/widgets/post_generation_dashboard.dart';

import 'dart:io';
import 'package:uuid/uuid.dart';

class PdfSettingsSheet extends ConsumerStatefulWidget {
  const PdfSettingsSheet({super.key});

  @override
  ConsumerState<PdfSettingsSheet> createState() => _PdfSettingsSheetState();
}

class _PdfSettingsSheetState extends ConsumerState<PdfSettingsSheet> {
  final TextEditingController _fileNameController = TextEditingController(
    text: 'DocSathi_Document',
  );
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _watermarkTextController =
      TextEditingController();
  bool _isGenerating = false;
  double _progress = 0.0;
  String _progressMessage = '';

  @override
  void dispose() {
    _fileNameController.dispose();
    _passwordController.dispose();
    _watermarkTextController.dispose();
    super.dispose();
  }

  Future<void> _generatePdf() async {
    setState(() {
      _isGenerating = true;
      _progress = 0.1;
      _progressMessage = 'Preparing document...';
    });

    try {
      final workspaceState = ref.read(workspaceProvider);
      final notifier = ref.read(pdfSettingsProvider.notifier);

      await notifier.updateSettings(
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
        watermarkText: _watermarkTextController.text.isNotEmpty
            ? _watermarkTextController.text
            : null,
      );

      // Use effective paths from WorkspaceState
      final pages = workspaceState.pages;

      setState(() {
        _progress = 0.3;
        _progressMessage = 'Processing images...';
      });

      final pdfPath = await PdfService.generatePdfFromImages(
        pages: pages,
        compressionLevel: workspaceState.compressionLevel,
        settings: ref.read(pdfSettingsProvider),
        onProgress: (progress, message) {
          if (mounted) {
            setState(() {
              _progress = 0.3 + (progress * 0.6);
              _progressMessage = message;
            });
          }
        },
      );

      // Add document to repository
      final file = File(pdfPath);
      final size = await file.length();
      final docModel = DocumentModel(
        id: const Uuid().v4(),
        filePath: pdfPath,
        fileName: _fileNameController.text.isNotEmpty
            ? _fileNameController.text
            : 'DocSathi_Document',
        createdAt: DateTime.now(),
        sizeInBytes: size,
        pageCount: pages.length,
      );

      await ref.read(documentListProvider.notifier).addDocument(docModel);

      setState(() {
        _progress = 1.0;
        _progressMessage = 'Complete!';
      });

      if (mounted) {
        // Pop the settings sheet first
        Navigator.pop(context);

        // Show the post-generation rich action dashboard
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          builder: (context) => PostGenerationDashboard(
            pdfPath: pdfPath,
            fileName: _fileNameController.text,
            imagePaths: pages.map((p) => p.effectivePath).toList(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Stack(
          children: [
            _SettingsForm(
              scrollController: scrollController,
              fileNameController: _fileNameController,
            ),
            _GenerateButton(
              isGenerating: _isGenerating,
              onGenerate: _generatePdf,
            ),
            if (_isGenerating)
              _ProgressOverlay(
                progress: _progress,
                progressMessage: _progressMessage,
              ),
          ],
        );
      },
    );
  }
}

class _SettingsForm extends ConsumerWidget {
  final ScrollController scrollController;
  final TextEditingController fileNameController;

  const _SettingsForm({
    required this.scrollController,
    required this.fileNameController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(pdfSettingsProvider);
    final notifier = ref.read(pdfSettingsProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'PDF Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                TextField(
                  controller: fileNameController,
                  decoration: const InputDecoration(
                    labelText: 'File Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Show Page Numbers'),
                  value: settings.showPageNumbers,
                  onChanged: (val) =>
                      notifier.updateSettings(showPageNumbers: val),
                ),
                ListTile(
                  title: const Text('Background Color'),
                  trailing: DropdownButton<String>(
                    value: settings.backgroundColor == Colors.black ? 'Black' : 'White',
                    items: ['White', 'Black']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        notifier.updateSettings(
                          backgroundColor: val == 'Black' ? Colors.black : Colors.white,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 80), // Padding for bottom button
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  final bool isGenerating;
  final VoidCallback onGenerate;

  const _GenerateButton({required this.isGenerating, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: FilledButton.icon(
        onPressed: isGenerating ? null : onGenerate,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Generate PDF', style: TextStyle(fontSize: 16)),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _ProgressOverlay extends StatelessWidget {
  final double progress;
  final String progressMessage;

  const _ProgressOverlay({
    required this.progress,
    required this.progressMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('${(progress * 100).toInt()}%'),
                  const SizedBox(height: 8),
                  Text(progressMessage, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
