import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsathi/features/image_resize/data/models/image_resize_models.dart';
import 'package:docsathi/features/image_resize/services/image_process_service.dart';

class ImageResizeController extends Notifier<ImageResizeState> {
  Timer? _debounceTimer;

  @override
  ImageResizeState build() {
    return ImageResizeState();
  }

  void updateSettings(GlobalResizeSettings newSettings) {
    state = state.copyWith(settings: newSettings);
    _debouncedRecalculatePreviews();
  }

  void _debouncedRecalculatePreviews() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _recalculatePreviews();
    });
  }

  Future<void> _recalculatePreviews() async {
    if (state.items.isEmpty) return;

    state = state.copyWith(isProcessing: true, processingMessage: 'Updating previews...');

    try {
      final updatedItems = await ImageProcessService.generatePreviews(state.items, state.settings);
      state = state.copyWith(items: updatedItems, isProcessing: false);
    } catch (e) {
      state = state.copyWith(isProcessing: false);
    }
  }

  Future<void> addImages(List<String> paths) async {
    state = state.copyWith(isProcessing: true, processingMessage: 'Loading images...');

    try {
      final newItems = await ImageProcessService.loadImages(paths);
      final allItems = [...state.items, ...newItems];

      final updatedItems = await ImageProcessService.generatePreviews(allItems, state.settings);

      state = state.copyWith(items: updatedItems, isProcessing: false);
    } catch (e) {
      state = state.copyWith(isProcessing: false);
    }
  }

  void removeImage(int index) {
    final newItems = List<ResizeImageItem>.from(state.items);
    newItems.removeAt(index);
    state = state.copyWith(items: newItems);
  }

  void clearAll() {
    state = state.copyWith(items: []);
  }

  Future<void> replaceImage(int index, String newPath) async {
    state = state.copyWith(isProcessing: true, processingMessage: 'Replacing image...');
    try {
      final newItems = await ImageProcessService.loadImages([newPath]);
      if (newItems.isNotEmpty) {
        final currentItems = List<ResizeImageItem>.from(state.items);
        currentItems[index] = newItems.first;

        final updatedItems = await ImageProcessService.generatePreviews(currentItems, state.settings);
        state = state.copyWith(items: updatedItems, isProcessing: false);
      } else {
        state = state.copyWith(isProcessing: false);
      }
    } catch (e) {
      state = state.copyWith(isProcessing: false);
    }
  }

  Future<void> pushEdit(int index, String newPath) async {
    final item = state.items[index];

    // If we're not at the end of history, truncate the future history
    List<String> newHistory = List.from(item.editHistoryPaths);
    if (item.historyIndex < newHistory.length - 1) {
      newHistory = newHistory.sublist(0, item.historyIndex + 1);
    }

    newHistory.add(newPath);

    final updatedItem = item.copyWith(
      editHistoryPaths: newHistory,
      historyIndex: newHistory.length - 1,
    );

    final currentItems = List<ResizeImageItem>.from(state.items);
    currentItems[index] = updatedItem;

    state = state.copyWith(
      items: currentItems,
      isProcessing: true,
      processingMessage: 'Updating preview...'
    );

    try {
      final itemsWithPreview = await ImageProcessService.generatePreviews(currentItems, state.settings);
      state = state.copyWith(items: itemsWithPreview, isProcessing: false);
    } catch (e) {
       state = state.copyWith(isProcessing: false);
    }
  }

  Future<void> undoEdit(int index) async {
    final item = state.items[index];
    if (item.canUndo) {
      final updatedItem = item.copyWith(historyIndex: item.historyIndex - 1);
      final currentItems = List<ResizeImageItem>.from(state.items);
      currentItems[index] = updatedItem;

      state = state.copyWith(
        items: currentItems,
        isProcessing: true,
        processingMessage: 'Updating preview...'
      );

      try {
        final itemsWithPreview = await ImageProcessService.generatePreviews(currentItems, state.settings);
        state = state.copyWith(items: itemsWithPreview, isProcessing: false);
      } catch (e) {
         state = state.copyWith(isProcessing: false);
      }
    }
  }

  Future<void> redoEdit(int index) async {
    final item = state.items[index];
    if (item.canRedo) {
      final updatedItem = item.copyWith(historyIndex: item.historyIndex + 1);
      final currentItems = List<ResizeImageItem>.from(state.items);
      currentItems[index] = updatedItem;

      state = state.copyWith(
        items: currentItems,
        isProcessing: true,
        processingMessage: 'Updating preview...'
      );

      try {
        final itemsWithPreview = await ImageProcessService.generatePreviews(currentItems, state.settings);
        state = state.copyWith(items: itemsWithPreview, isProcessing: false);
      } catch (e) {
         state = state.copyWith(isProcessing: false);
      }
    }
  }
}

final imageResizeProvider = NotifierProvider<ImageResizeController, ImageResizeState>(() {
  return ImageResizeController();
});
