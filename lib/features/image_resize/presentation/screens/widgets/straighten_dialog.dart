import 'dart:io';
import 'package:flutter/material.dart';

class StraightenDialog extends StatefulWidget {
  final String imagePath;

  const StraightenDialog({super.key, required this.imagePath});

  @override
  State<StraightenDialog> createState() => _StraightenDialogState();
}

class _StraightenDialogState extends State<StraightenDialog> {
  double _angle = 0.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Straighten Image'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 200,
            child: Transform.rotate(
              angle: _angle * 3.14159 / 180,
              child: Image.file(File(widget.imagePath)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Angle: ${_angle.toStringAsFixed(1)}°'),
          Slider(
            value: _angle,
            min: -45.0,
            max: 45.0,
            onChanged: (val) {
              setState(() {
                _angle = val;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _angle),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
