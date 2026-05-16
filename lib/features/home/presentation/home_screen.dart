import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<_ToolItem> _tools = [
    _ToolItem(
      title: 'Photo to PDF',
      subtitle: 'Convert photos into polished PDF documents.',
      icon: Icons.picture_as_pdf_rounded,
      route: '/photo-to-pdf',
      active: true,
      accent: Color(0xFFB71C1C),
    ),
    _ToolItem(
      title: 'Resize Image',
      subtitle: 'Resize for exact dimension and KB requirements.',
      icon: Icons.photo_size_select_large_rounded,
      route: '/resize',
      active: true,
      accent: Color(0xFF0D47A1),
    ),
    _ToolItem(
      title: 'PDF Editor',
      subtitle: 'Reorder, remove, and update PDF pages.',
      icon: Icons.edit_document,
      route: '/pdf-edit',
      active: false,
      accent: Color(0xFF4A148C),
    ),
    _ToolItem(
      title: 'Merge PDF',
      subtitle: 'Combine multiple PDFs into one file.',
      icon: Icons.merge_type,
      route: '/pdf-merge',
      active: false,
      accent: Color(0xFF1B5E20),
    ),
    _ToolItem(
      title: 'Compress Image',
      subtitle: 'Reduce file size while preserving quality.',
      icon: Icons.compress_rounded,
      route: '/compress',
      active: false,
      accent: Color(0xFF004D40),
    ),
    _ToolItem(
      title: 'Scan Document',
      subtitle: 'Capture and clean documents from camera.',
      icon: Icons.document_scanner,
      route: '/scan',
      active: false,
      accent: Color(0xFF37474F),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final activeTools = _tools.where((tool) => tool.active).length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            title: const Text('DocSathi'),
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 76, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Utilities for Daily Documents',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$activeTools active tools • Offline-first workflow',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _QuickActionsRow(
                onPhotoTap: () => context.push('/photo-to-pdf'),
                onResizeTap: () => context.push('/resize'),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'All Utilities',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final tool = _tools[index];
                return _ToolCard(
                  tool: tool,
                  onTap: () {
                    if (tool.active) {
                      context.push(tool.route);
                    } else {
                      _showComingSoonBottomSheet(context, tool.title);
                    }
                  },
                );
              }, childCount: _tools.length),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonBottomSheet(BuildContext context, String featureName) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 44, color: Colors.orange),
              const SizedBox(height: 12),
              Text(
                '$featureName is Coming Soon',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This feature is in progress. We are designing it to be fast and reliable.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onPhotoTap;
  final VoidCallback onResizeTap;

  const _QuickActionsRow({
    required this.onPhotoTap,
    required this.onResizeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            label: 'New PDF',
            icon: Icons.add_circle_outline,
            onTap: onPhotoTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            label: 'Resize Now',
            icon: Icons.tune,
            onTap: onResizeTap,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final _ToolItem tool;
  final VoidCallback onTap;

  const _ToolCard({required this.tool, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(context).disabledColor;
    final accent = tool.active ? tool.accent : mutedColor;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tool.icon, color: accent, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                tool.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: tool.active ? null : mutedColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tool.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tool.active
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : mutedColor,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(tool.active ? 'Available' : 'Soon'),
                  side: BorderSide.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final bool active;
  final Color accent;

  const _ToolItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.active,
    required this.accent,
  });
}
