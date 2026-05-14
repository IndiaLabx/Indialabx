import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:docsathi/features/image_resize/presentation/controllers/image_resize_controller.dart';
import 'package:docsathi/features/image_resize/presentation/screens/widgets/workspace_card.dart';
import 'package:docsathi/features/image_resize/presentation/screens/widgets/global_settings_panel.dart';
import 'package:docsathi/features/image_resize/services/export_service.dart';

class ImageResizeScreen extends ConsumerWidget {
  const ImageResizeScreen({super.key});

  Future<void> _pickImages(WidgetRef ref) async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      ref.read(imageResizeProvider.notifier).addImages(images.map((e) => e.path).toList());
    }
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const GlobalSettingsPanel(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imageResizeProvider);
    final notifier = ref.read(imageResizeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resize & Compress'),
        actions: [
          if (state.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear All',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All'),
                    content: const Text('Are you sure you want to remove all images from the queue?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          notifier.clearAll();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          if (state.items.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_size_select_large, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No images selected', style: TextStyle(color: Colors.grey, fontSize: 18)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _pickImages(ref),
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Select Photos'),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                return WorkspaceCard(index: index);
              },
            ),

          if (state.isProcessing)
            Container(
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
                        Text(state.processingMessage),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: state.items.isNotEmpty
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'settings_fab',
                  onPressed: () => _showSettings(context),
                  icon: const Icon(Icons.settings),
                  label: const Text('Settings'),
                ),
                const SizedBox(width: 16),
                FloatingActionButton.extended(
                  heroTag: 'export_fab',
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting...')));
                    final result = await ExportService.exportImages(state.items, state.settings);
                    if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result ?? 'Export Failed')));
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                ),
              ],
            )
          : null,
    );
  }
}
