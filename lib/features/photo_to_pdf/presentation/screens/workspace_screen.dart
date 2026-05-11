import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/workspace_controller.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/screens/widgets/pdf_settings_sheet.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/screens/widgets/fluid_deck.dart';
import 'package:go_router/go_router.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  bool _isEditingName = false;
  PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final workspaceState = ref.read(workspaceProvider);
      if (workspaceState.pages.isEmpty) {
        final didPick = await ref.read(workspaceProvider.notifier).pickImages();
        if (!didPick && mounted) {
          context.go('/photo-to-pdf');
        }
      }
      _nameController.text = workspaceState.documentName;
    });

    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus) {
        setState(() {
          _isEditingName = false;
        });
        ref
            .read(workspaceProvider.notifier)
            .setDocumentName(_nameController.text);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PdfSettingsSheet(),
    );
  }

  String _calculateEstimatedSize(WorkspaceState state) {
    if (state.pages.isEmpty) {
      return '0 B';
    }

    int totalOriginalBytes = 0;
    for (var page in state.pages) {
      totalOriginalBytes += page.originalSizeBytes;
    }

    double compressionFactor = 1.0;
    switch (state.compressionLevel) {
      case CompressionLevel.high:
        compressionFactor = 0.8;
        break;
      case CompressionLevel.balanced:
        compressionFactor = 0.4;
        break;
      case CompressionLevel.max:
        compressionFactor = 0.15;
        break;
    }

    final estimatedBytes = (totalOriginalBytes * compressionFactor).toInt();

    if (estimatedBytes < 1024 * 1024) {
      return '${(estimatedBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(estimatedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceProvider);
    final notifier = ref.read(workspaceProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (workspaceState.mode == WorkspaceMode.focus) {
              notifier.setMode(WorkspaceMode.grid);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Row(
          children: [
            Expanded(
              child: _isEditingName
                  ? TextField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      onSubmitted: (value) {
                        setState(() {
                          _isEditingName = false;
                        });
                        notifier.setDocumentName(value);
                      },
                    )
                  : GestureDetector(
                      onTap: () {
                        setState(() {
                          _isEditingName = true;
                        });
                        _nameFocusNode.requestFocus();
                      },
                      child: Text(
                        workspaceState.documentName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Est: ${_calculateEstimatedSize(workspaceState)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
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
          if (workspaceState.pages.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No photos selected',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => notifier.pickImages(),
                    icon: const Icon(Icons.add),
                    label: const Text('Select Photos'),
                  ),
                ],
              ),
            )
          else if (workspaceState.mode == WorkspaceMode.grid)
            Padding(
              padding: const EdgeInsets.only(
                left: 8.0,
                right: 8.0,
                top: 8.0,
                bottom: 200.0,
              ), // Padding for toolbars
              child: ReorderableGridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: workspaceState.pages.length,
                onReorder: notifier.reorderImages,
                itemBuilder: (context, index) {
                  final page = workspaceState.pages[index];
                  return _ImageGridItem(
                    key: ValueKey(page.effectivePath),
                    page: page,
                    index: index,
                    onTap: () {
                      notifier.setFocusedPage(index);
                      notifier.setMode(WorkspaceMode.focus);
                      _pageController.dispose();
                      _pageController = PageController(initialPage: index);
                    },
                    onDelete: () => notifier.removeImage(index),
                  );
                },
              ),
            )
          else
            // Focus Mode: Swipeable Pager
            Padding(
              padding: const EdgeInsets.only(bottom: 200.0),
              child: PageView.builder(
                controller: _pageController,
                itemCount: workspaceState.pages.length,
                onPageChanged: (index) => notifier.setFocusedPage(index),
                itemBuilder: (context, index) {
                  final page = workspaceState.pages[index];
                  return Hero(
                    tag: 'hero_workspace_image_${index}_${page.effectivePath}',
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _FilteredImage(
                        page: page,
                        fit: BoxFit.contain,
                        useHighRes: true,
                      ),
                    ),
                  );
                },
              ),
            ),

          if (workspaceState.mode == WorkspaceMode.focus)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Page ${workspaceState.focusedPageIndex + 1} of ${workspaceState.pages.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          const FluidDeck(),

          if (workspaceState.isProcessing)
            Container(
              color: Colors.black45,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(workspaceState.processingMessage),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: workspaceState.pages.isNotEmpty
          ? AnimatedPadding(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(
                bottom: workspaceState.activeTool == ActiveToolTier.none
                    ? 70.0
                    : 230.0,
              ),
              child: FloatingActionButton.extended(
                onPressed: _showSettingsSheet,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Create PDF'),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _FilteredImage extends ConsumerWidget {
  final DocumentPage page;
  final BoxFit fit;
  final bool useHighRes;

  const _FilteredImage({
    required this.page,
    this.fit = BoxFit.cover,
    this.useHighRes = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget image;
    if (useHighRes || page.thumbnailBytes.isEmpty) {
      image = Image.file(File(page.effectivePath), fit: fit);
    } else {
      image = Image.memory(page.thumbnailBytes, fit: fit);
    }

    if (page.filterType == FilterType.grayscale) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: image,
      );
    } else if (page.filterType == FilterType.enhanced) {
      // Simple contrast/brightness enhancement matrix
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          1.2,
          0,
          0,
          0,
          10,
          0,
          1.2,
          0,
          0,
          10,
          0,
          0,
          1.2,
          0,
          10,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: image,
      );
    }

    return image;
  }
}

class _ImageGridItem extends ConsumerWidget {
  final DocumentPage page;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ImageGridItem({
    required super.key,
    required this.page,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'hero_workspace_image_${index}_${page.effectivePath}',
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _FilteredImage(page: page, fit: BoxFit.cover),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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
            ],
          ),
        ),
      ),
    );
  }
}
