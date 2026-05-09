import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';

class PostGenerationDashboard extends StatelessWidget {
  final String pdfPath;
  final String fileName;
  final List<String> imagePaths;

  const PostGenerationDashboard({
    super.key,
    required this.pdfPath,
    required this.fileName,
    required this.imagePaths,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  void _sharePdf() async {
    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(pdfPath)], text: 'Here is my document from DocSathi!');
  }

  void _saveToGallery(BuildContext context) async {
    try {
      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        hasAccess = await Gal.requestAccess();
      }

      if (hasAccess) {
        for (final path in imagePaths) {
          await Gal.putImage(path);
        }
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Images saved to gallery successfully!')),
           );
        }
      }
    } on GalException catch (e) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save: ${e.type.message}')),
           );
        }
    } catch (e) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
           );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(pdfPath);
    final sizeStr = file.existsSync() ? _formatSize(file.lengthSync()) : 'Unknown Size';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
               child: Container(
                 width: 40,
                 height: 4,
                 margin: const EdgeInsets.only(bottom: 16),
                 decoration: BoxDecoration(
                   color: Colors.grey.shade400,
                   borderRadius: BorderRadius.circular(2),
                 ),
               ),
            ),

            // Header Card
            Card(
              elevation: 0,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Success • $sizeStr',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Grid
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                _buildActionButton(context, Icons.share, 'Share', _sharePdf),
                _buildActionButton(context, Icons.photo_library, 'Save to Gallery', () => _saveToGallery(context)),
                _buildActionButton(context, Icons.compress, 'Compress', () {
                    // Logic to adjust compression in settings
                    Navigator.pop(context);
                }),
                _buildActionButton(context, Icons.lock, 'Lock', () {
                    // Logic to open password input
                    Navigator.pop(context);
                }),
              ],
            ),

            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                // Popping this bottom sheet effectively acts as 'Edit'
                // since it preserves WorkspaceState and leaves them in WorkspaceScreen
                Navigator.pop(context);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Back to Editor'),
              style: FilledButton.styleFrom(
                 padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
