import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final photoSelectionProvider = NotifierProvider<PhotoSelectionNotifier, List<String>>(() {
  return PhotoSelectionNotifier();
});

class PhotoSelectionNotifier extends Notifier<List<String>> {
  final ImagePicker _picker = ImagePicker();

  @override
  List<String> build() {
    return [];
  }

  Future<void> pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        state = [...state, ...images.map((e) => e.path)];
      }
    } catch (e) {
      // Handle error quietly or throw
    }
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final paths = List<String>.from(state);
    final item = paths.removeAt(oldIndex);
    paths.insert(newIndex, item);
    state = paths;
  }

  void removeImage(int index) {
    final paths = List<String>.from(state);
    paths.removeAt(index);
    state = paths;
  }

  void updateImage(int index, String newPath) {
    final paths = List<String>.from(state);
    paths[index] = newPath;
    state = paths;
  }

  void clear() {
    state = [];
  }
}
