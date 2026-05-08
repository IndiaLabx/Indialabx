import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:docsathi/features/photo_to_pdf/application/photo_to_pdf_provider.dart';

class PhotoToPdfScreen extends ConsumerWidget {
  const PhotoToPdfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(photoToPdfProvider);
    final notifier = ref.read(photoToPdfProvider.notifier);

    // Show error if any
    ref.listen<PhotoToPdfState>(photoToPdfProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
      if (next.generatedPdfPath != null && next.generatedPdfPath != previous?.generatedPdfPath) {
        _showSuccessDialog(context, next.generatedPdfPath!, notifier);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo to PDF'),
        actions: [
          if (state.imagePaths.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: state.isGenerating ? null : () => notifier.generatePdf(),
              tooltip: 'Generate PDF',
            ),
        ],
      ),
      body: state.imagePaths.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 16),
                  Text(
                    'No photos selected',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).disabledColor),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => notifier.pickImages(),
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add Photos'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ReorderableGridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: state.imagePaths.length,
                    onReorder: notifier.reorderImages,
                    itemBuilder: (context, index) {
                      final path = state.imagePaths[index];
                      return _ImageGridItem(
                        key: ValueKey(path),
                        path: path,
                        index: index,
                        onDelete: () => notifier.removeImage(index),
                      );
                    },
                  ),
                ),
                if (state.isGenerating)
                  Container(
                    color: Colors.black45,
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
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
      floatingActionButton: state.imagePaths.isNotEmpty && !state.isGenerating
          ? FloatingActionButton(
              onPressed: () => notifier.pickImages(),
              tooltip: 'Add more photos',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showSuccessDialog(BuildContext context, String pdfPath, PhotoToPdfNotifier notifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success!'),
        content: const Text('Your PDF has been generated successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.reset();
            },
            child: const Text('Done'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Share.shareXFiles([XFile(pdfPath)], text: 'Here is my PDF generated with DocSathi!');
            },
            icon: const Icon(Icons.share),
            label: const Text('Share PDF'),
          ),
        ],
      ),
    );
  }
}

class _ImageGridItem extends StatelessWidget {
  final String path;
  final int index;
  final VoidCallback onDelete;

  const _ImageGridItem({
    required super.key,
    required this.path,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(path),
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.white),
              onPressed: onDelete,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
                padding: EdgeInsets.zero,
                minimumSize: const Size(24, 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
