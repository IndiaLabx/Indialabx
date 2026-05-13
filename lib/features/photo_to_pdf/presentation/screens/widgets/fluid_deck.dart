import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/workspace_controller.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/pdf_settings_controller.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:docsathi/features/photo_to_pdf/services/image_service.dart';

class FluidDeck extends ConsumerStatefulWidget {
  const FluidDeck({super.key});

  @override
  ConsumerState<FluidDeck> createState() => _FluidDeckState();
}

class _FluidDeckState extends ConsumerState<FluidDeck> {
  late TextEditingController _watermarkController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(pdfSettingsProvider);
    _watermarkController = TextEditingController(text: settings.watermarkText);
    _passwordController = TextEditingController(text: settings.password);
  }

  @override
  void dispose() {
    _watermarkController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspaceProvider);
    final notifier = ref.read(workspaceProvider.notifier);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tier 2: Morphing Panel
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            height: state.activeTool == ActiveToolTier.none ? 0 : 160, // Taller to accommodate Watermark sliders
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: _buildTier2Content(context, state, notifier, ref),
            ),
          ),

          // Tier 1: Anchor Categories
          Container(
            height: 60,
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildTier1Icon(
                  context,
                  state,
                  notifier,
                  ActiveToolTier.adjust,
                  Icons.crop_rotate,
                  'Adjust',
                ),
                _buildTier1Icon(
                  context,
                  state,
                  notifier,
                  ActiveToolTier.filters,
                  Icons.color_lens,
                  'Filters',
                ),
                _buildTier1Icon(
                  context,
                  state,
                  notifier,
                  ActiveToolTier.quality,
                  Icons.compress,
                  'Quality',
                ),
                _buildTier1Icon(
                  context,
                  state,
                  notifier,
                  ActiveToolTier.watermark,
                  Icons.branding_watermark,
                  'Watermark',
                ),
                _buildTier1Icon(
                  context,
                  state,
                  notifier,
                  ActiveToolTier.layout,
                  Icons.auto_awesome_mosaic,
                  'Layout',
                ),
                _buildTier1Icon(
                  context,
                  state,
                  notifier,
                  ActiveToolTier.security,
                  Icons.lock,
                  'Security',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTier1Icon(
    BuildContext context,
    WorkspaceState state,
    WorkspaceController notifier,
    ActiveToolTier tier,
    IconData icon,
    String label,
  ) {
    final isActive = state.activeTool == tier;
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        avatar: Icon(
          icon,
          size: 18,
          color: isActive ? Colors.white : Colors.grey,
        ),
        selected: isActive,
        onSelected: (selected) {
          notifier.setTool(selected ? tier : ActiveToolTier.none);
        },
        selectedColor: primaryColor,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isActive ? primaryColor : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildTier2Content(
    BuildContext context,
    WorkspaceState state,
    WorkspaceController notifier,
    WidgetRef ref,
  ) {
    if (state.activeTool == ActiveToolTier.none) return const SizedBox.shrink();

    switch (state.activeTool) {
      case ActiveToolTier.adjust:
        return _buildAdjustTier2(context, state, notifier);
      case ActiveToolTier.filters:
        return _buildFiltersTier2(context, state, notifier);
      case ActiveToolTier.quality:
        return _buildQualityTier2(context, state, notifier);
      case ActiveToolTier.watermark:
        return _buildWatermarkTier2(context, ref);
      case ActiveToolTier.layout:
        return _buildLayoutTier2(context, ref);
      case ActiveToolTier.security:
        return _buildSecurityTier2(context, ref);
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _handleCrop(
    BuildContext context,
    WorkspaceState state,
    WorkspaceController notifier,
  ) async {
    if (state.pages.isEmpty) return;

    final currentPage = state.pages[state.focusedPageIndex];

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: currentPage.effectivePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Theme.of(context).primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
        ),
      ],
    );

    if (croppedFile != null) {
      final newThumbnail = await ImageService.generateThumbnail(
        croppedFile.path,
      );
      final updatedPage = currentPage.copyWith(
        croppedPath: croppedFile.path,
        thumbnailBytes: newThumbnail,
      );
      notifier.updatePage(state.focusedPageIndex, updatedPage);
    }
  }

  Future<void> _handleRotate(
    BuildContext context,
    WorkspaceState state,
    WorkspaceController notifier,
  ) async {
    if (state.pages.isEmpty) return;
    final currentPage = state.pages[state.focusedPageIndex];

    // We will rotate 90 degrees clockwise
    final rotatedPath = await ImageService.rotateImage(
      currentPage.effectivePath,
      90,
    );
    final newThumbnail = await ImageService.generateThumbnail(rotatedPath);

    final updatedPage = currentPage.copyWith(
      croppedPath:
          rotatedPath, // Treat rotation as a new crop to keep effectivePath logic intact
      thumbnailBytes: newThumbnail,
    );
    notifier.updatePage(state.focusedPageIndex, updatedPage);
  }

  Widget _buildAdjustTier2(
    BuildContext context,
    WorkspaceState state,
    WorkspaceController notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.crop),
            label: const Text('Crop'),
            onPressed: state.mode == WorkspaceMode.focus
                ? () => _handleCrop(context, state, notifier)
                : null,
          ),
          TextButton.icon(
            icon: const Icon(Icons.rotate_right),
            label: const Text('Rotate'),
            onPressed: state.mode == WorkspaceMode.focus
                ? () => _handleRotate(context, state, notifier)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersTier2(
    BuildContext context,
    WorkspaceState state,
    WorkspaceController notifier,
  ) {
    if (state.pages.isEmpty) return const SizedBox.shrink();
    final currentPage = state.pages[state.focusedPageIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _filterChoice(
                context,
                'Original',
                FilterType.original,
                currentPage.filterType,
                notifier,
              ),
              _filterChoice(
                context,
                'Grayscale',
                FilterType.grayscale,
                currentPage.filterType,
                notifier,
              ),
              _filterChoice(
                context,
                'Enhanced',
                FilterType.enhanced,
                currentPage.filterType,
                notifier,
              ),
              _filterChoice(
                context,
                'Magic',
                FilterType.magic,
                currentPage.filterType,
                notifier,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Apply to All Pages', style: TextStyle(fontSize: 12)),
              Switch(
                value: state.applyFilterToAll,
                onChanged: (val) => notifier.setApplyFilterToAll(val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChoice(
    BuildContext context,
    String label,
    FilterType type,
    FilterType currentType,
    WorkspaceController notifier,
  ) {
    final isSelected = type == currentType;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          notifier.applyFilterToCurrentPage(type);
        }
      },
    );
  }

  Widget _buildQualityTier2(
    BuildContext context,
    WorkspaceState state,
    WorkspaceController notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        children: [
          const Text(
            'Compression Level',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<CompressionLevel>(
            segments: const [
              ButtonSegment(value: CompressionLevel.high, label: Text('High')),
              ButtonSegment(
                value: CompressionLevel.balanced,
                label: Text('Balanced'),
              ),
              ButtonSegment(value: CompressionLevel.max, label: Text('Max')),
            ],
            selected: {state.compressionLevel},
            onSelectionChanged: (Set<CompressionLevel> newSelection) {
              notifier.setCompressionLevel(newSelection.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWatermarkTier2(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(pdfSettingsProvider);
    final notifier = ref.read(pdfSettingsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _watermarkController,
            decoration: const InputDecoration(
              labelText: 'Watermark Text',
              isDense: true,
            ),
            onChanged: (val) {
              notifier.updateSettings(watermarkText: val);
            },
          ),
          if (settings.watermarkText != null &&
              settings.watermarkText!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Opacity',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Slider(
                        value: settings.watermarkOpacity,
                        min: 0.1,
                        max: 1.0,
                        onChanged: (val) =>
                            notifier.updateSettings(watermarkOpacity: val),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Size',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Slider(
                        value: settings.watermarkSize,
                        min: 10.0,
                        max: 100.0,
                        onChanged: (val) =>
                            notifier.updateSettings(watermarkSize: val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLayoutTier2(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(pdfSettingsProvider);
    final notifier = ref.read(pdfSettingsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Page Size',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: settings.pageSize,
                items: ['A4', 'Letter', 'Fit']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) notifier.updateSettings(pageSize: val);
                },
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Margins',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: settings.margin,
                items: ['None', 'Small', 'Medium']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) notifier.updateSettings(margin: val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTier2(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(pdfSettingsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: TextField(
        controller: _passwordController,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'PDF Password (Optional)',
          isDense: true,
        ),
        onChanged: (val) {
          notifier.updateSettings(password: val);
        },
      ),
    );
  }
}
