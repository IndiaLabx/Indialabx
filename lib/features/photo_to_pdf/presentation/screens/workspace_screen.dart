import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/photo_selection_controller.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/screens/widgets/pdf_settings_sheet.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:docsathi/features/photo_to_pdf/services/image_service.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  bool _isProcessing = false;

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const PdfSettingsSheet(),
    );
  }

  void _showImageOptions(BuildContext context, String path, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.crop),
              title: const Text('Crop'),
              onTap: () {
                Navigator.pop(context);
                _cropImage(path, index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.rotate_right),
              title: const Text('Rotate 90°'),
              onTap: () {
                Navigator.pop(context);
                _rotateImage(path, index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Color Filter'),
              onTap: () {
                Navigator.pop(context);
                _applyColorFilter(path, index);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ref.read(photoSelectionProvider.notifier).removeImage(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cropImage(String path, int index) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Crop Image',
        ),
      ],
    );

    if (croppedFile != null) {
      ref.read(photoSelectionProvider.notifier).updateImage(index, croppedFile.path);
    }
  }

  Future<void> _rotateImage(String path, int index) async {
    setState(() => _isProcessing = true);
    final newPath = await ImageService.rotateImage(path, 90);
    ref.read(photoSelectionProvider.notifier).updateImage(index, newPath);
    setState(() => _isProcessing = false);
  }

  Future<void> _applyColorFilter(String path, int index) async {
    final filter = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Color Mode'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'Original'),
            child: const Text('Original'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'Grayscale'),
            child: const Text('Grayscale'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'Black & White'),
            child: const Text('Black & White'),
          ),
        ],
      ),
    );

    if (filter != null) {
      setState(() => _isProcessing = true);
      final newPath = await ImageService.applyColorFilter(path, filter);
      ref.read(photoSelectionProvider.notifier).updateImage(index, newPath);
      setState(() => _isProcessing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final imagePaths = ref.read(photoSelectionProvider);
      if (imagePaths.isEmpty) {
        ref.read(photoSelectionProvider.notifier).pickImages();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final imagePaths = ref.watch(photoSelectionProvider);
    final notifier = ref.read(photoSelectionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Studio Workspace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: () => notifier.pickImages(),
            tooltip: 'Add more photos',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (imagePaths.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No photos selected', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => notifier.pickImages(),
                    icon: const Icon(Icons.add),
                    label: const Text('Select Photos'),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0, bottom: 80.0),
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
                    onTap: () => _showImageOptions(context, path, index),
                    onDelete: () => notifier.removeImage(index),
                  );
                },
              ),
            ),

          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: imagePaths.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showSettingsSheet,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Create PDF'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _ImageGridItem extends StatelessWidget {
  final String path;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ImageGridItem({
    required super.key,
    required this.path,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
            Positioned(
              top: -4,
              right: -4,
              child: IconButton(
                icon: const Icon(Icons.cancel, color: Colors.white, size: 20),
                onPressed: onDelete,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black38,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(24, 24),
                ),
              ),
            ),
            const Positioned(
              bottom: 4,
              right: 4,
              child: Icon(Icons.edit, color: Colors.white70, size: 20),
            )
          ],
        ),
      ),
    );
  }
}
