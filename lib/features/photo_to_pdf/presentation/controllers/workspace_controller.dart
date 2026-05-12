import 'dart:io';


import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:docsathi/features/photo_to_pdf/services/image_service.dart';

Future<String> calculateSizeOffThread(WorkspaceState state) async {
  return compute((WorkspaceState s) {
    if (s.pages.isEmpty) return '0 KB';
    int totalBytes = 0;
    for (final page in s.pages) {
      totalBytes += page.originalSizeBytes;
    }
    double compressionFactor = 1.0;
    switch (s.compressionLevel) {
      case CompressionLevel.high:
        compressionFactor = 0.8;
        break;
      case CompressionLevel.balanced:
        compressionFactor = 0.4;
        break;
      case CompressionLevel.max:
        compressionFactor = 0.15;
        break;
    }
    final estBytes = (totalBytes * compressionFactor).toInt();
    if (estBytes < 1024 * 1024) {
      return '${(estBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(estBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }, state);
}

final estimatedSizeProvider = FutureProvider.autoDispose<String>((ref) {
  final state = ref.watch(workspaceProvider);
  return calculateSizeOffThread(state);
});

enum WorkspaceMode { grid, focus }
enum ActiveToolTier { none, adjust, layout, filters, quality, watermark, security }
enum FilterType { original, grayscale, enhanced }
enum CompressionLevel { high, balanced, max }

class DocumentPage {
  final String originalPath;
  final Uint8List thumbnailBytes;
  final String? croppedPath;
  final int rotationAngle;
  final FilterType filterType;
  final int originalSizeBytes;

  DocumentPage({
    required this.originalPath,
    required this.thumbnailBytes,
    this.croppedPath,
    this.rotationAngle = 0,
    this.filterType = FilterType.original,
    this.originalSizeBytes = 0,
  });

  String get effectivePath => croppedPath ?? originalPath;

  DocumentPage copyWith({
    String? originalPath,
    Uint8List? thumbnailBytes,
    String? croppedPath,
    int? rotationAngle,
    FilterType? filterType,
    int? originalSizeBytes,
  }) {
    return DocumentPage(
      originalPath: originalPath ?? this.originalPath,
      thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes,
      croppedPath: croppedPath ?? this.croppedPath,
      rotationAngle: rotationAngle ?? this.rotationAngle,
      filterType: filterType ?? this.filterType,
      originalSizeBytes: originalSizeBytes ?? this.originalSizeBytes,
    );
  }
}

class WorkspaceState {
  final List<DocumentPage> pages;
  final WorkspaceMode mode;
  final ActiveToolTier activeTool;
  final int focusedPageIndex;
  final String documentName;
  final bool isProcessing;
  final String processingMessage;
  final CompressionLevel compressionLevel;
  final bool applyFilterToAll;

  WorkspaceState({
    this.pages = const [],
    this.mode = WorkspaceMode.grid,
    this.activeTool = ActiveToolTier.none,
    this.focusedPageIndex = 0,
    this.documentName = 'DocSathi_Document',
    this.isProcessing = false,
    this.processingMessage = '',
    this.compressionLevel = CompressionLevel.balanced,
    this.applyFilterToAll = false,
  });

  WorkspaceState copyWith({
    List<DocumentPage>? pages,
    WorkspaceMode? mode,
    ActiveToolTier? activeTool,
    int? focusedPageIndex,
    String? documentName,
    bool? isProcessing,
    String? processingMessage,
    CompressionLevel? compressionLevel,
    bool? applyFilterToAll,
  }) {
    return WorkspaceState(
      pages: pages ?? this.pages,
      mode: mode ?? this.mode,
      activeTool: activeTool ?? this.activeTool,
      focusedPageIndex: focusedPageIndex ?? this.focusedPageIndex,
      documentName: documentName ?? this.documentName,
      isProcessing: isProcessing ?? this.isProcessing,
      processingMessage: processingMessage ?? this.processingMessage,
      compressionLevel: compressionLevel ?? this.compressionLevel,
      applyFilterToAll: applyFilterToAll ?? this.applyFilterToAll,
    );
  }
}

class WorkspaceController extends Notifier<WorkspaceState> {
  @override
  WorkspaceState build() {
    return WorkspaceState();
  }

  Future<bool> pickImages() async {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
          await addImages(images.map((e) => e.path).toList());
          return true;
      }
      return false;
  }

  Future<void> addImages(List<String> paths) async {
    state = state.copyWith(
      isProcessing: true,
      processingMessage: 'Loading images...',
    );
    try {
        final thumbnails = await ImageService.generateThumbnailsInIsolate(paths);
        final newPages = <DocumentPage>[];
        for (int i = 0; i < paths.length; i++) {
            final file = File(paths[i]);
            final size = await file.exists() ? await file.length() : 0;
            newPages.add(DocumentPage(
                originalPath: paths[i],
                thumbnailBytes: thumbnails[i],
                originalSizeBytes: size,
            ));
        }
        state = state.copyWith(pages: [...state.pages, ...newPages], isProcessing: false);
    } catch(e) {
        state = state.copyWith(isProcessing: false);
    }
  }

  void setPages(List<DocumentPage> pages) {
    state = state.copyWith(pages: pages);
  }

  void removeImage(int index) {
    final newPages = List<DocumentPage>.from(state.pages);
    newPages.removeAt(index);
    state = state.copyWith(pages: newPages);
  }

  void reorderImages(int oldIndex, int newIndex) {
    final newPages = List<DocumentPage>.from(state.pages);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = newPages.removeAt(oldIndex);
    newPages.insert(newIndex, item);
    state = state.copyWith(pages: newPages);
  }

  void updatePage(int index, DocumentPage page) {
    final newPages = List<DocumentPage>.from(state.pages);
    newPages[index] = page;
    state = state.copyWith(pages: newPages);
  }

  void setMode(WorkspaceMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setFocusedPage(int index) {
    state = state.copyWith(focusedPageIndex: index);
  }

  void setTool(ActiveToolTier tool) {
    state = state.copyWith(activeTool: tool);
  }

  void setDocumentName(String name) {
    state = state.copyWith(documentName: name);
  }

  void setCompressionLevel(CompressionLevel level) {
    state = state.copyWith(compressionLevel: level);
  }

  void setApplyFilterToAll(bool apply) {
    state = state.copyWith(applyFilterToAll: apply);
  }

  void applyFilterToCurrentPage(FilterType filter) {
    if (state.pages.isEmpty) return;

    if (state.applyFilterToAll) {
      final newPages = state.pages.map((p) => p.copyWith(filterType: filter)).toList();
      state = state.copyWith(pages: newPages);
    } else {
      final page = state.pages[state.focusedPageIndex];
      final newPage = page.copyWith(filterType: filter);
      updatePage(state.focusedPageIndex, newPage);
    }
  }

  void clear() {
    state = WorkspaceState();
  }
}

final workspaceProvider = NotifierProvider<WorkspaceController, WorkspaceState>(
  () {
    return WorkspaceController();
  },
);
