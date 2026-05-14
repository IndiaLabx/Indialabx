import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsathi/features/image_resize/presentation/controllers/image_resize_controller.dart';
import 'package:docsathi/features/image_resize/data/models/image_resize_models.dart';

class GlobalSettingsPanel extends ConsumerWidget {
  const GlobalSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imageResizeProvider);
    final settings = state.settings;
    final notifier = ref.read(imageResizeProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('Global Resize Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              // Mode Selector
              SegmentedButton<ResizeMode>(
                segments: const [
                  ButtonSegment(value: ResizeMode.percentage, label: Text('Percentage')),
                  ButtonSegment(value: ResizeMode.dimensions, label: Text('Dimensions')),
                ],
                selected: {settings.resizeMode},
                onSelectionChanged: (newSelection) {
                  notifier.updateSettings(settings.copyWith(resizeMode: newSelection.first));
                },
              ),
              const SizedBox(height: 16),

              // Percentage Slider
              if (settings.resizeMode == ResizeMode.percentage)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scale: ${settings.percentage.toInt()}%'),
                    Slider(
                      value: settings.percentage,
                      min: 10,
                      max: 200,
                      divisions: 19,
                      label: '${settings.percentage.toInt()}%',
                      onChanged: (val) => notifier.updateSettings(settings.copyWith(percentage: val)),
                    ),
                  ],
                ),

              // Dimensions Inputs
              if (settings.resizeMode == ResizeMode.dimensions)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Width', suffixText: 'px'),
                        controller: TextEditingController(text: settings.targetWidth.toString()),
                        onSubmitted: (val) {
                          if (int.tryParse(val) != null) {
                            notifier.updateSettings(settings.copyWith(targetWidth: int.parse(val)));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Height', suffixText: 'px'),
                        controller: TextEditingController(text: settings.targetHeight.toString()),
                        enabled: !settings.lockAspectRatio,
                        onSubmitted: (val) {
                          if (int.tryParse(val) != null) {
                            notifier.updateSettings(settings.copyWith(targetHeight: int.parse(val)));
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(settings.lockAspectRatio ? Icons.link : Icons.link_off),
                      onPressed: () => notifier.updateSettings(settings.copyWith(lockAspectRatio: !settings.lockAspectRatio)),
                    ),
                  ],
                ),

              const Divider(height: 32),

              // Output Format
              const Text('Output Format', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<OutputFormat>(
                value: settings.format,
                isExpanded: true,
                items: OutputFormat.values.map((f) => DropdownMenuItem(value: f, child: Text(f.name.toUpperCase()))).toList(),
                onChanged: (val) {
                  if (val != null) notifier.updateSettings(settings.copyWith(format: val));
                },
              ),
              const SizedBox(height: 16),

              // Target File Size Optimizer
              SwitchListTile(
                title: const Text('Optimize for Target File Size'),
                subtitle: const Text('Automatically adjust quality to hit byte limit.'),
                value: settings.useTargetFileSize,
                onChanged: (settings.format == OutputFormat.jpeg || settings.format == OutputFormat.webp)
                    ? (val) => notifier.updateSettings(settings.copyWith(useTargetFileSize: val))
                    : null, // Disabled for PNG since it's lossless
              ),

              if (settings.useTargetFileSize && (settings.format == OutputFormat.jpeg || settings.format == OutputFormat.webp))
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Row(
                    children: [
                      const Text('Target Size: '),
                      Expanded(
                        child: Slider(
                          value: settings.targetFileSizeBytes.toDouble(),
                          min: 10 * 1024, // 10KB
                          max: 2000 * 1024, // 2MB
                          onChanged: (val) => notifier.updateSettings(settings.copyWith(targetFileSizeBytes: val.toInt())),
                        ),
                      ),
                      Text('${(settings.targetFileSizeBytes / 1024).toStringAsFixed(0)} KB'),
                    ],
                  ),
                )
              else if (settings.format != OutputFormat.png)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quality: ${settings.quality.toInt()}%'),
                    Slider(
                      value: settings.quality,
                      min: 10,
                      max: 100,
                      divisions: 9,
                      label: '${settings.quality.toInt()}%',
                      onChanged: (val) => notifier.updateSettings(settings.copyWith(quality: val)),
                    ),
                  ],
                ),

              const Divider(height: 32),

              // Advanced Settings
              const Text('Advanced', style: TextStyle(fontWeight: FontWeight.bold)),
              ListTile(
                title: const Text('Global Rotation'),
                trailing: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('0°')),
                    ButtonSegment(value: 90, label: Text('90°')),
                    ButtonSegment(value: 180, label: Text('180°')),
                    ButtonSegment(value: 270, label: Text('270°')),
                  ],
                  selected: {settings.globalRotation},
                  onSelectionChanged: (val) => notifier.updateSettings(settings.copyWith(globalRotation: val.first)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Watermark Text', border: OutlineInputBorder()),
                  controller: TextEditingController(text: settings.watermarkText),
                  onSubmitted: (val) => notifier.updateSettings(settings.copyWith(watermarkText: val)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
