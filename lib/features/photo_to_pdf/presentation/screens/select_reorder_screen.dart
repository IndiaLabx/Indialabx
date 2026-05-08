import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/photo_selection_controller.dart';

class SelectReorderScreen extends ConsumerWidget {
  const SelectReorderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagePaths = ref.watch(photoSelectionProvider);
    final notifier = ref.read(photoSelectionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select & Reorder'),
        actions: [
          if (imagePaths.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => context.push('/photo-to-pdf/edit'),
              tooltip: 'Next: Edit',
            ),
        ],
      ),
      body: imagePaths.isEmpty
          ? Center(
              child: FilledButton.icon(
                onPressed: () => notifier.pickImages(),
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Select Photos'),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ReorderableGridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: imagePaths.length,
                onReorder: notifier.reorderImages,
                itemBuilder: (context, index) {
                  final path = imagePaths[index];
                  return _ImageGridItem(
                    key: ValueKey(path),
                    path: path,
                    index: index,
                    onDelete: () => notifier.removeImage(index),
                  );
                },
              ),
            ),
      floatingActionButton: imagePaths.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => notifier.pickImages(),
              tooltip: 'Add more photos',
              child: const Icon(Icons.add),
            )
          : null,
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
