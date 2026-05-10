import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/workspace_controller.dart';

class FluidDeck extends ConsumerWidget {
  const FluidDeck({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            height: state.activeTool == ActiveToolTier.none ? 0 : 80, // Slide up
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: SingleChildScrollView(
              child: _buildTier2Content(context, state, notifier),
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
                _buildTier1Icon(context, state, notifier, ActiveToolTier.adjust, Icons.crop_rotate, 'Adjust'),
                _buildTier1Icon(context, state, notifier, ActiveToolTier.layout, Icons.auto_awesome_mosaic, 'Layout'),
                _buildTier1Icon(context, state, notifier, ActiveToolTier.filters, Icons.color_lens, 'Filters'),
                _buildTier1Icon(context, state, notifier, ActiveToolTier.quality, Icons.compress, 'Quality'),
                _buildTier1Icon(context, state, notifier, ActiveToolTier.watermark, Icons.branding_watermark, 'Watermark'),
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
    String label
  ) {
    final isActive = state.activeTool == tier;
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        avatar: Icon(icon, size: 18, color: isActive ? Colors.white : Colors.grey),
        selected: isActive,
        onSelected: (selected) {
          notifier.setTool(selected ? tier : ActiveToolTier.none);
        },
        selectedColor: primaryColor,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isActive ? primaryColor : Colors.grey.shade300)),
      ),
    );
  }

  Widget _buildTier2Content(BuildContext context, WorkspaceState state, WorkspaceController notifier) {
    if (state.activeTool == ActiveToolTier.none) return const SizedBox.shrink();

    switch (state.activeTool) {
      case ActiveToolTier.adjust:
        return _buildAdjustTier2(context);
      case ActiveToolTier.layout:
        return const Padding(
           padding: EdgeInsets.all(16.0),
           child: Center(child: Text("Layout Settings: A4, Margin, Auto Apply")),
        );
      case ActiveToolTier.filters:
        return const Padding(
           padding: EdgeInsets.all(16.0),
           child: Center(child: Text("Filter Settings: B&W, Grayscale")),
        );
      case ActiveToolTier.quality:
        return const Padding(
           padding: EdgeInsets.all(16.0),
           child: Center(child: Text("Quality: High, Balanced, Max")),
        );
      case ActiveToolTier.watermark:
        return const Padding(
           padding: EdgeInsets.all(16.0),
           child: Center(child: Text("Watermark: Text, Color, Opacity")),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAdjustTier2(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.crop),
            label: const Text('Crop'),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Cropping feature coming soon!')),
               );
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.rotate_right),
            label: const Text('Rotate'),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Rotation feature coming soon!')),
               );
            },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.done_all),
            label: const Text('Apply to All'),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Batch edit feature coming soon!')),
               );
            },
          ),
        ],
      ),
    );
  }
}
