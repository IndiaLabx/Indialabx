import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsathi/features/photo_to_pdf/data/models/pdf_settings_model.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/pdf_settings_controller.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/controllers/workspace_controller.dart';
import 'package:docsathi/features/photo_to_pdf/services/pdf_service.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/screens/widgets/post_generation_dashboard.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class PdfSettingsSheet extends ConsumerStatefulWidget {
  const PdfSettingsSheet({super.key});

  @override
  ConsumerState<PdfSettingsSheet> createState() => _PdfSettingsSheetState();
}

class _PdfSettingsSheetState extends ConsumerState<PdfSettingsSheet> {
  final TextEditingController _fileNameController = TextEditingController(text: 'DocSathi_Document');
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _watermarkTextController = TextEditingController();
  bool _isGenerating = false;
  double _progress = 0.0;
  String _progressMessage = '';

  @override
  void dispose() {
    _fileNameController.dispose();
    _passwordController.dispose();
    _watermarkTextController.dispose();
    super.dispose();
  }

  Future<void> _generatePdf() async {
    setState(() {
      _isGenerating = true;
      _progress = 0.1;
      _progressMessage = 'Preparing document...';
    });

    try {
      final workspaceState = ref.read(workspaceProvider);
      final notifier = ref.read(pdfSettingsProvider.notifier);

      await notifier.updateSettings(
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
        watermarkText: _watermarkTextController.text.isNotEmpty ? _watermarkTextController.text : null,
      );

      // Use effective paths from WorkspaceState
      final imagePaths = workspaceState.pages.map((p) => p.effectivePath).toList();

      setState(() {
        _progress = 0.3;
        _progressMessage = 'Processing images...';
      });

      final pdfPath = await PdfService.generatePdfFromImages(
        imagePaths: imagePaths,
        settings: ref.read(pdfSettingsProvider),
        onProgress: (progress, message) {
          if (mounted) {
            setState(() {
              _progress = 0.3 + (progress * 0.6);
              _progressMessage = message;
            });
          }
        },
      );

      setState(() {
        _progress = 1.0;
        _progressMessage = 'Complete!';
      });

      if (mounted) {
        // Pop the settings sheet first
        Navigator.pop(context);

        // Show the post-generation rich action dashboard
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: const RoundedRectangleBorder(
             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => PostGenerationDashboard(
             pdfPath: pdfPath,
             fileName: _fileNameController.text,
             imagePaths: imagePaths,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _showColorPicker(BuildContext context, Color currentColor, Function(Color) onColorChanged) {
    showDialog(
      context: context,
      builder: (context) {
        Color pickerColor = currentColor;
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) => pickerColor = color,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Got it'),
              onPressed: () {
                onColorChanged(pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(pdfSettingsProvider);
    final notifier = ref.read(pdfSettingsProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text('PDF Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        TextField(
                          controller: _fileNameController,
                          decoration: const InputDecoration(
                            labelText: 'File Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionHeader('Basic Settings'),
                        _buildDropdownRow(
                          'Page Size',
                          settings.pageSize,
                          ['A4', 'Letter', 'Fit'],
                          (val) => notifier.updateSettings(pageSize: val),
                        ),
                        _buildDropdownRow(
                          'Orientation',
                          settings.orientation,
                          ['Portrait', 'Landscape'],
                          (val) => notifier.updateSettings(orientation: val),
                        ),
                        _buildDropdownRow(
                          'Margin',
                          settings.margin,
                          ['None', 'Small', 'Medium'],
                          (val) => notifier.updateSettings(margin: val),
                        ),
                        const Divider(),
                        _buildSectionHeader('Quality & Performance'),
                        _buildDropdownRow(
                          'Image Compression',
                          settings.imageQuality.name,
                          ImageQuality.values.map((e) => e.name).toList(),
                          (val) {
                            final quality = ImageQuality.values.firstWhere((e) => e.name == val);
                            notifier.updateSettings(imageQuality: quality);
                          },
                        ),
                        const Divider(),
                        _buildSectionHeader('Security & Watermark'),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'PDF Password (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _watermarkTextController,
                          decoration: const InputDecoration(
                            labelText: 'Watermark Text (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.branding_watermark),
                          ),
                        ),
                        if (_watermarkTextController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ListTile(
                            title: const Text('Watermark Color'),
                            trailing: GestureDetector(
                              onTap: () => _showColorPicker(context, settings.watermarkColor, (color) {
                                notifier.updateSettings(watermarkColor: color);
                              }),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: settings.watermarkColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                          _buildSliderRow(
                            'Opacity',
                            settings.watermarkOpacity,
                            0.1,
                            1.0,
                            (val) => notifier.updateSettings(watermarkOpacity: val),
                          ),
                          _buildSliderRow(
                            'Size',
                            settings.watermarkSize,
                            10.0,
                            100.0,
                            (val) => notifier.updateSettings(watermarkSize: val),
                          ),
                          _buildSliderRow(
                            'Angle',
                            settings.watermarkAngle,
                            -90.0,
                            90.0,
                            (val) => notifier.updateSettings(watermarkAngle: val),
                          ),
                        ],
                        const Divider(),
                        SwitchListTile(
                          title: const Text('Show Page Numbers'),
                          value: settings.showPageNumbers,
                          onChanged: (val) => notifier.updateSettings(showPageNumbers: val),
                        ),
                        const SizedBox(height: 80), // Padding for bottom button
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: FilledButton.icon(
                onPressed: _isGenerating ? null : _generatePdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generate PDF', style: TextStyle(fontSize: 16)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (_isGenerating)
              Positioned.fill(
                child: Container(
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
                            Text('${(_progress * 100).toInt()}%'),
                            const SizedBox(height: 8),
                            Text(_progressMessage, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
      ),
    );
  }

  Widget _buildDropdownRow(String label, String value, List<String> items, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          DropdownButton<String>(
            value: items.contains(value) ? value : items.first,
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(String label, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('$label: ${value.toStringAsFixed(1)}'),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
