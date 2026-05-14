import 'dart:typed_data';

enum ResizeMode { percentage, dimensions }
enum OutputFormat { jpeg, png, webp }

class GlobalResizeSettings {
  final ResizeMode resizeMode;
  final double percentage; // 1.0 to 100.0+
  final int targetWidth;
  final int targetHeight;
  final bool lockAspectRatio;

  final OutputFormat format;
  final double quality; // 1.0 to 100.0 (for lossy)

  final bool useTargetFileSize;
  final int targetFileSizeBytes; // e.g. 100 * 1024 for 100KB

  final int globalRotation; // 0, 90, 180, 270

  final String watermarkText;
  final double watermarkOpacity;
  final double watermarkSize;
  final bool watermarkTiled;
  final int watermarkRotation;

  GlobalResizeSettings({
    this.resizeMode = ResizeMode.percentage,
    this.percentage = 100.0,
    this.targetWidth = 1000,
    this.targetHeight = 1000,
    this.lockAspectRatio = true,
    this.format = OutputFormat.jpeg,
    this.quality = 85.0,
    this.useTargetFileSize = false,
    this.targetFileSizeBytes = 102400, // 100KB default
    this.globalRotation = 0,
    this.watermarkText = '',
    this.watermarkOpacity = 0.5,
    this.watermarkSize = 24.0,
    this.watermarkTiled = false,
    this.watermarkRotation = 0,
  });

  GlobalResizeSettings copyWith({
    ResizeMode? resizeMode,
    double? percentage,
    int? targetWidth,
    int? targetHeight,
    bool? lockAspectRatio,
    OutputFormat? format,
    double? quality,
    bool? useTargetFileSize,
    int? targetFileSizeBytes,
    int? globalRotation,
    String? watermarkText,
    double? watermarkOpacity,
    double? watermarkSize,
    bool? watermarkTiled,
    int? watermarkRotation,
  }) {
    return GlobalResizeSettings(
      resizeMode: resizeMode ?? this.resizeMode,
      percentage: percentage ?? this.percentage,
      targetWidth: targetWidth ?? this.targetWidth,
      targetHeight: targetHeight ?? this.targetHeight,
      lockAspectRatio: lockAspectRatio ?? this.lockAspectRatio,
      format: format ?? this.format,
      quality: quality ?? this.quality,
      useTargetFileSize: useTargetFileSize ?? this.useTargetFileSize,
      targetFileSizeBytes: targetFileSizeBytes ?? this.targetFileSizeBytes,
      globalRotation: globalRotation ?? this.globalRotation,
      watermarkText: watermarkText ?? this.watermarkText,
      watermarkOpacity: watermarkOpacity ?? this.watermarkOpacity,
      watermarkSize: watermarkSize ?? this.watermarkSize,
      watermarkTiled: watermarkTiled ?? this.watermarkTiled,
      watermarkRotation: watermarkRotation ?? this.watermarkRotation,
    );
  }
}

class ResizeImageItem {
  final String originalPath;
  final String filename;
  final int originalSizeBytes;
  final int originalWidth;
  final int originalHeight;

  // Destructive Edit History: paths to temporarily saved images
  final List<String> editHistoryPaths;
  final int historyIndex;

  // Cached data for UI preview based on current global settings
  final Uint8List? previewThumbnail;
  final int estimatedFinalSizeBytes;
  final int estimatedFinalWidth;
  final int estimatedFinalHeight;

  ResizeImageItem({
    required this.originalPath,
    required this.filename,
    required this.originalSizeBytes,
    required this.originalWidth,
    required this.originalHeight,
    required this.editHistoryPaths,
    this.historyIndex = 0,
    this.previewThumbnail,
    this.estimatedFinalSizeBytes = 0,
    this.estimatedFinalWidth = 0,
    this.estimatedFinalHeight = 0,
  });

  String get currentActivePath {
    if (editHistoryPaths.isEmpty) return originalPath;
    if (historyIndex >= 0 && historyIndex < editHistoryPaths.length) {
      return editHistoryPaths[historyIndex];
    }
    return originalPath;
  }

  bool get canUndo => historyIndex > 0;
  bool get canRedo => historyIndex < editHistoryPaths.length - 1;

  ResizeImageItem copyWith({
    String? originalPath,
    String? filename,
    int? originalSizeBytes,
    int? originalWidth,
    int? originalHeight,
    List<String>? editHistoryPaths,
    int? historyIndex,
    Uint8List? previewThumbnail,
    int? estimatedFinalSizeBytes,
    int? estimatedFinalWidth,
    int? estimatedFinalHeight,
  }) {
    return ResizeImageItem(
      originalPath: originalPath ?? this.originalPath,
      filename: filename ?? this.filename,
      originalSizeBytes: originalSizeBytes ?? this.originalSizeBytes,
      originalWidth: originalWidth ?? this.originalWidth,
      originalHeight: originalHeight ?? this.originalHeight,
      editHistoryPaths: editHistoryPaths ?? this.editHistoryPaths,
      historyIndex: historyIndex ?? this.historyIndex,
      previewThumbnail: previewThumbnail ?? this.previewThumbnail,
      estimatedFinalSizeBytes: estimatedFinalSizeBytes ?? this.estimatedFinalSizeBytes,
      estimatedFinalWidth: estimatedFinalWidth ?? this.estimatedFinalWidth,
      estimatedFinalHeight: estimatedFinalHeight ?? this.estimatedFinalHeight,
    );
  }
}

class ImageResizeState {
  final List<ResizeImageItem> items;
  final GlobalResizeSettings settings;
  final bool isProcessing;
  final String processingMessage;

  ImageResizeState({
    this.items = const [],
    GlobalResizeSettings? settings,
    this.isProcessing = false,
    this.processingMessage = '',
  }) : settings = settings ?? GlobalResizeSettings();

  ImageResizeState copyWith({
    List<ResizeImageItem>? items,
    GlobalResizeSettings? settings,
    bool? isProcessing,
    String? processingMessage,
  }) {
    return ImageResizeState(
      items: items ?? this.items,
      settings: settings ?? this.settings,
      isProcessing: isProcessing ?? this.isProcessing,
      processingMessage: processingMessage ?? this.processingMessage,
    );
  }
}
