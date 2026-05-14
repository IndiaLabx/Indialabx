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

  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<String> _progressMessageNotifier = ValueNotifier<String>('');

  @override
  void dispose() {
    _fileNameController.dispose();
    _passwordController.dispose();
    _watermarkTextController.dispose();
    _progressNotifier.dispose();
    _progressMessageNotifier.dispose();
    super.dispose();
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<double>(
                        valueListenable: _progressNotifier,
                        builder: (context, value, child) {
                          return Text('${(value * 100).toInt()}%');
                        },
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<String>(
                        valueListenable: _progressMessageNotifier,
                        builder: (context, value, child) {
                          return Text(value, textAlign: TextAlign.center);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _generatePdf() async {
    setState(() {
      _isGenerating = true;
    });

    _progressNotifier.value = 0.1;
    _progressMessageNotifier.value = 'Preparing document...';

    _showLoadingDialog();

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

      final pages = workspaceState.pages;

      _progressNotifier.value = 0.3;
      _progressMessageNotifier.value = 'Processing images...';

      final pdfPath = await PdfService.generatePdfFromImages(
        pages: pages,
        compressionLevel: workspaceState.compressionLevel,
        settings: ref.read(pdfSettingsProvider),
        onProgress: (progress, message) {
          _progressNotifier.value = 0.3 + (progress * 0.6);
          _progressMessageNotifier.value = message;
        },
      );

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

      _progressNotifier.value = 1.0;
      _progressMessageNotifier.value = 'Complete!';

      _hideLoadingDialog();

      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        Navigator.pop(context);

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          builder: (context) => PostGenerationDashboard(
            pdfPath: pdfPath,
            fileName: _fileNameController.text,
            pages: pages,
          ),
        );
      }
    } catch (e) {
      _hideLoadingDialog();
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
                const SizedBox(height: 80),
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
