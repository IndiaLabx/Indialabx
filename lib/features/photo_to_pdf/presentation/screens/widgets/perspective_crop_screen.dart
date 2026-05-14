import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_document_scanner/flutter_document_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class PerspectiveCropScreen extends StatefulWidget {
  final String imagePath;

  const PerspectiveCropScreen({super.key, required this.imagePath});

  @override
  State<PerspectiveCropScreen> createState() => _PerspectiveCropScreenState();
}

class _PerspectiveCropScreenState extends State<PerspectiveCropScreen> {
  final _controller = DocumentScannerController();
  static const _uuid = Uuid();
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initScanner() async {
    try {
      await _controller.findContoursFromExternalImage(
        image: File(widget.imagePath),
      );
    } catch (e) {
      debugPrint('Error initializing document scanner: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    }
  }

  Future<void> _handleSave(Uint8List imageBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final newPath = path.join(tempDir.path, '${_uuid.v4()}.jpg');
      final file = File(newPath);
      await file.writeAsBytes(imageBytes);
      if (mounted) {
        Navigator.pop(context, newPath);
      }
    } catch (e) {
      debugPrint('Error saving cropped image: $e');
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: DocumentScanner(
          controller: _controller,
          onSave: _handleSave,
          generalStyles: const GeneralStyles(
            hideDefaultDialogs: true,
            baseColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
