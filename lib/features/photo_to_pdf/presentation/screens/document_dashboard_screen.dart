import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/document_controller.dart';
import 'package:intl/intl.dart';
import 'package:docsathi/core/utils/file_security.dart';

class DocumentDashboardScreen extends ConsumerWidget {
  const DocumentDashboardScreen({super.key});

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Photo to PDF')),
      body: documents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No documents yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create a new PDF',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ExpansionTile(
                    leading: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                      size: 36,
                    ),
                    title: Text(
                      doc.fileName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${DateFormat.yMMMd().format(doc.createdAt)} • ${_formatSize(doc.sizeInBytes)} • ${doc.pageCount} Pages',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                context.push(
                                  '/photo-to-pdf/preview',
                                  extra: doc.filePath,
                                );
                              },
                              icon: const Icon(Icons.visibility),
                              label: const Text('View'),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                if (await FileSecurity.isPathSafe(
                                  doc.filePath,
                                )) {
                                  // ignore: deprecated_member_use
                                  await Share.shareXFiles([
                                    XFile(doc.filePath),
                                  ], text: 'Here is my document!');
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Error: File cannot be shared for security reasons.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                ref
                                    .read(documentListProvider.notifier)
                                    .deleteDocument(doc.id);
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/photo-to-pdf/workspace'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
