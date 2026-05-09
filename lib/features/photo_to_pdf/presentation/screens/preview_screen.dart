import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/workspace_controller.dart';
import 'package:printing/printing.dart';
import 'dart:io';

class PreviewScreen extends ConsumerWidget {
  final String pdfPath;
  const PreviewScreen({super.key, required this.pdfPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              // ignore: deprecated_member_use
              await Share.shareXFiles([XFile(pdfPath)], text: 'Here is my document from DocSathi!');
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => File(pdfPath).readAsBytes(),
        allowSharing: false,
        allowPrinting: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: FilledButton(
            onPressed: () {
              ref.read(workspaceProvider.notifier).clear();
              context.go('/photo-to-pdf');
            },
            child: const Text('Done'),
          ),
        ),
      ),
    );
  }
}
