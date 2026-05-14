import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:docsathi/features/image_resize/presentation/controllers/image_resize_controller.dart';
import 'package:docsathi/features/image_resize/services/image_process_service.dart';
import 'package:docsathi/features/image_resize/presentation/screens/widgets/straighten_dialog.dart';
import 'package:docsathi/features/image_resize/presentation/screens/widgets/crop_dialog.dart';

class WorkspaceCard extends ConsumerWidget {
  final int index;

  const WorkspaceCard({super.key, required this.index});

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  void _showInfoDialog(BuildContext context, var item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Metadata'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filename: ${item.filename}'),
            const SizedBox(height: 8),
            Text('Original Size: ${_formatBytes(item.originalSizeBytes)}'),
            Text('Original Dims: ${item.originalWidth}x${item.originalHeight}'),
            const Divider(),
            const Text('Current Estimates:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Final Size: ${_formatBytes(item.estimatedFinalSizeBytes)}'),
            Text('Final Dims: ${item.estimatedFinalWidth}x${item.estimatedFinalHeight}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
        ],
      )
    );
  }

  Future<void> _handleReplace(WidgetRef ref) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ref.read(imageResizeProvider.notifier).replaceImage(index, image.path);
    }
  }

  Future<void> _handleStraighten(BuildContext context, WidgetRef ref, String path) async {
    final angle = await showDialog<double>(
      context: context,
      builder: (context) => StraightenDialog(imagePath: path),
    );

    if (angle != null && angle != 0.0) {
      if (context.mounted) {
         // Show a loading indicator since this takes time
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Straightening image...')));
         final newPath = await ImageProcessService.straightenImage(path, angle);
         if (context.mounted) {
            ref.read(imageResizeProvider.notifier).pushEdit(index, newPath);
         }
      }
    }
  }

  Future<void> _handleCrop(BuildContext context, WidgetRef ref, String path) async {
    final croppedPath = await CropHelper.cropImage(context, path);
    if (croppedPath != null && context.mounted) {
       ref.read(imageResizeProvider.notifier).pushEdit(index, croppedPath);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imageResizeProvider);
    if (index >= state.items.length) return const SizedBox.shrink();

    final item = state.items[index];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Image Preview Area
          SizedBox(
            height: 200,
            width: double.infinity,
            child: item.previewThumbnail != null
              ? Image.memory(item.previewThumbnail!, fit: BoxFit.contain)
              : Image.file(File(item.currentActivePath), fit: BoxFit.contain),
          ),

          // Info Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.filename,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${_formatBytes(item.originalSizeBytes)} ➔ ${_formatBytes(item.estimatedFinalSizeBytes)}',
                  style: TextStyle(
                    color: item.estimatedFinalSizeBytes < item.originalSizeBytes ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Toolbar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: item.canUndo ? () => ref.read(imageResizeProvider.notifier).undoEdit(index) : null,
                  tooltip: 'Undo',
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  onPressed: item.canRedo ? () => ref.read(imageResizeProvider.notifier).redoEdit(index) : null,
                  tooltip: 'Redo',
                ),
                const SizedBox(width: 8, child: VerticalDivider()),
                IconButton(
                  icon: const Icon(Icons.crop),
                  onPressed: () => _handleCrop(context, ref, item.currentActivePath),
                  tooltip: 'Crop',
                ),
                IconButton(
                  icon: const Icon(Icons.rotate_right),
                  onPressed: () => _handleStraighten(context, ref, item.currentActivePath),
                  tooltip: 'Straighten',
                ),
                const SizedBox(width: 8, child: VerticalDivider()),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _showInfoDialog(context, item),
                  tooltip: 'Info',
                ),
                IconButton(
                  icon: const Icon(Icons.find_replace),
                  onPressed: () => _handleReplace(ref),
                  tooltip: 'Replace',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => ref.read(imageResizeProvider.notifier).removeImage(index),
                  tooltip: 'Remove',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
