import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:photo_view/photo_view.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/photo_selection_controller.dart';
import 'package:docsathi/features/photo_to_pdf/services/image_service.dart';

class EditScreen extends ConsumerStatefulWidget {
  const EditScreen({super.key});

  @override
  ConsumerState<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends ConsumerState<EditScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isProcessing = false;

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
  Widget build(BuildContext context) {
    final imagePaths = ref.watch(photoSelectionProvider);

    if (imagePaths.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit')),
        body: const Center(child: Text('No images to edit')),
      );
    }

    final currentPath = imagePaths[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Page ${_currentIndex + 1}/${imagePaths.length}'),
        actions: [
          TextButton(
            onPressed: () => context.push('/photo-to-pdf/settings'),
            child: const Text('Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: imagePaths.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return PhotoView(
                      imageProvider: FileImage(File(imagePaths[index])),
                      backgroundDecoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
                    );
                  },
                ),
              ),
              Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.crop),
                      tooltip: 'Crop',
                      onPressed: () => _cropImage(currentPath, _currentIndex),
                    ),
                    IconButton(
                      icon: const Icon(Icons.rotate_right),
                      tooltip: 'Rotate',
                      onPressed: () => _rotateImage(currentPath, _currentIndex),
                    ),
                    IconButton(
                      icon: const Icon(Icons.color_lens),
                      tooltip: 'Color Filter',
                      onPressed: () => _applyColorFilter(currentPath, _currentIndex),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
