import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:docsathi/core/services/pdf_service.dart';

class PhotoToPdfState {
  final List<String> imagePaths;
  final bool isGenerating;
  final String? generatedPdfPath;
  final String? error;

  PhotoToPdfState({
    this.imagePaths = const [],
    this.isGenerating = false,
    this.generatedPdfPath,
    this.error,
  });

  PhotoToPdfState copyWith({
    List<String>? imagePaths,
    bool? isGenerating,
    String? generatedPdfPath,
    String? error,
  }) {
    return PhotoToPdfState(
      imagePaths: imagePaths ?? this.imagePaths,
      isGenerating: isGenerating ?? this.isGenerating,
      generatedPdfPath: generatedPdfPath ?? this.generatedPdfPath,
      error: error ?? this.error,
    );
  }
}

class PhotoToPdfNotifier extends Notifier<PhotoToPdfState> {
  final ImagePicker _picker = ImagePicker();

  @override
  PhotoToPdfState build() {
    return PhotoToPdfState();
  }

  Future<void> pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        final currentPaths = List<String>.from(state.imagePaths);
        currentPaths.addAll(images.map((e) => e.path));
        state = state.copyWith(imagePaths: currentPaths, error: null);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to pick images: $e');
    }
  }

  void reorderImages(int oldIndex, int newIndex) {
    final paths = List<String>.from(state.imagePaths);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = paths.removeAt(oldIndex);
    paths.insert(newIndex, item);
    state = state.copyWith(imagePaths: paths);
  }

  void removeImage(int index) {
    final paths = List<String>.from(state.imagePaths);
    paths.removeAt(index);
    state = state.copyWith(imagePaths: paths);
  }

  Future<void> generatePdf() async {
    if (state.imagePaths.isEmpty) {
      state = state.copyWith(error: 'No images selected');
      return;
    }

    state = state.copyWith(isGenerating: true, error: null, generatedPdfPath: null);

    try {
      final pdfPath = await PdfService.generatePdfFromImages(state.imagePaths);
      state = state.copyWith(isGenerating: false, generatedPdfPath: pdfPath);
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: 'Failed to generate PDF: $e');
    }
  }

  void reset() {
    state = PhotoToPdfState();
  }
}

final photoToPdfProvider = NotifierProvider<PhotoToPdfNotifier, PhotoToPdfState>(() {
  return PhotoToPdfNotifier();
});
