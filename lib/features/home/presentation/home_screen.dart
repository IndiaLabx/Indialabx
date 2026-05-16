import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/document_controller.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2A39),
        elevation: 0,
        title: const Text(
          'Doc Scanner',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
          tooltip: 'Menu',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium, color: Color(0xFFFFC107)),
            onPressed: () {},
            tooltip: 'Premium',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
            tooltip: 'More options',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.home), SizedBox(width: 8), Text('Home')],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_center),
                  SizedBox(width: 8),
                  Text('PDF Tools'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildHomeTab(context, ref), _buildToolsTab(context)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/photo-to-pdf/workspace'),
        backgroundColor: Colors.blue.shade600,
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        label: const Text(
          'New PDF',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Filter Chips Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All docs'),
                selected: true,
                onSelected: (_) {},
                backgroundColor: Colors.white,
                selectedColor: Colors.blue,
                labelStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                showCheckmark: false,
                avatar: const Icon(
                  Icons.touch_app,
                  size: 16,
                  color: Colors.white,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Recent'),
                selected: false,
                onSelected: (_) {},
                backgroundColor: Colors.white,
                labelStyle: const TextStyle(color: Colors.black87),
                avatar: const Icon(
                  Icons.history,
                  size: 16,
                  color: Colors.black54,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Favourite'),
                selected: false,
                onSelected: (_) {},
                backgroundColor: Colors.white,
                labelStyle: const TextStyle(color: Colors.black87),
                avatar: const Icon(
                  Icons.star_border,
                  size: 16,
                  color: Colors.black54,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Documents List
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final documents = ref.watch(documentListProvider);

              if (documents.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final doc = documents[index];
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                            size: 32,
                          ),
                        ),
                      ),
                      title: Text(
                        doc.fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Text(
                              DateFormat('dd-MMM-yyyy').format(doc.createdAt),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${doc.pageCount}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.picture_as_pdf,
                              size: 14,
                              color: Colors.blue.shade700,
                            ),
                          ],
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_horiz),
                        onPressed: () {
                          context.push(
                            '/photo-to-pdf/preview',
                            extra: doc.filePath,
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No documents yet',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create a new PDF',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsTab(BuildContext context) {
    final tools = [
      {
        'title': 'Photo to PDF',
        'icon': Icons.picture_as_pdf,
        'route': '/photo-to-pdf',
        'active': true,
      },
      {
        'title': 'Resize Image',
        'icon': Icons.photo_size_select_large,
        'route': '/resize',
        'active': true,
      },
      {
        'title': 'PDF Editor',
        'icon': Icons.edit_document,
        'route': '/pdf-edit',
        'active': false,
      },
      {
        'title': 'Merge PDF',
        'icon': Icons.merge_type,
        'route': '/pdf-merge',
        'active': false,
      },
      {
        'title': 'Compress Image',
        'icon': Icons.compress,
        'route': '/compress',
        'active': false,
      },
      {
        'title': 'Scan Document',
        'icon': Icons.document_scanner,
        'route': '/scan',
        'active': false,
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        final isActive = tool['active'] as bool;

        return Card(
          elevation: isActive ? 2 : 0,
          color: isActive ? Colors.white : Colors.grey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isActive ? Colors.transparent : Colors.grey.shade200,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (isActive) {
                context.push(tool['route'] as String);
              } else {
                _showComingSoonBottomSheet(context, tool['title'] as String);
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.blue.shade50
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tool['icon'] as IconData,
                    size: 32,
                    color: isActive
                        ? Colors.blue.shade700
                        : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tool['title'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isActive ? Colors.black87 : Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!isActive) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      'Soon',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showComingSoonBottomSheet(BuildContext context, String featureName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                '$featureName is Coming Soon',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'This feature is currently under development. Stay tuned for updates!',
                style: TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('We will notify you when it is ready!'),
                        ),
                      );
                    },
                    child: const Text('Notify Me'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
