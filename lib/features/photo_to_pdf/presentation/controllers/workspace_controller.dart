import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:docsathi/features/photo_to_pdf/services/image_service.dart';

enum WorkspaceMode { grid, focus }
enum ActiveToolTier { none, adjust, layout, filters, quality, watermark }

class DocumentPage {
  final String originalPath;
  final Uint8List thumbnailBytes;
  final String? croppedPath;
  final int rotationAngle;
  final String colorFilter;

  DocumentPage({
    required this.originalPath,
    required this.thumbnailBytes,
    this.croppedPath,
    this.rotationAngle = 0,
    this.colorFilter = 'Original',
  });

  String get effectivePath => croppedPath ?? originalPath;

  DocumentPage copyWith({
    String? originalPath,
    Uint8List? thumbnailBytes,
    String? croppedPath,
    int? rotationAngle,
    String? colorFilter,
  }) {
    return DocumentPage(
      originalPath: originalPath ?? this.originalPath,
      thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes,
      croppedPath: croppedPath ?? this.croppedPath,
      rotationAngle: rotationAngle ?? this.rotationAngle,
      colorFilter: colorFilter ?? this.colorFilter,
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

  WorkspaceState({
    this.pages = const [],
    this.mode = WorkspaceMode.grid,
    this.activeTool = ActiveToolTier.none,
    this.focusedPageIndex = 0,
    this.documentName = 'DocSathi_Document',
    this.isProcessing = false,
    this.processingMessage = '',
  });

  WorkspaceState copyWith({
    List<DocumentPage>? pages,
    WorkspaceMode? mode,
    ActiveToolTier? activeTool,
    int? focusedPageIndex,
    String? documentName,
    bool? isProcessing,
    String? processingMessage,
  }) {
    return WorkspaceState(
      pages: pages ?? this.pages,
      mode: mode ?? this.mode,
      activeTool: activeTool ?? this.activeTool,
      focusedPageIndex: focusedPageIndex ?? this.focusedPageIndex,
      documentName: documentName ?? this.documentName,
      isProcessing: isProcessing ?? this.isProcessing,
      processingMessage: processingMessage ?? this.processingMessage,
    );
  }
}

class WorkspaceController extends Notifier<WorkspaceState> {
  @override
  WorkspaceState build() {
    return WorkspaceState();
  }

  Future<void> pickImages() async {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
          await addImages(images.map((e) => e.path).toList());
      }
  }

  Future<void> addImages(List<String> paths) async {
    state = state.copyWith(isProcessing: true, processingMessage: 'Loading images...');
    try {
        final thumbnails = await ImageService.generateThumbnailsInIsolate(paths);
        final newPages = <DocumentPage>[];
        for (int i = 0; i < paths.length; i++) {
            newPages.add(DocumentPage(originalPath: paths[i], thumbnailBytes: thumbnails[i]));
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

  void clear() {
    state = WorkspaceState();
  }
}

final workspaceProvider = NotifierProvider<WorkspaceController, WorkspaceState>(() {
  return WorkspaceController();
});
