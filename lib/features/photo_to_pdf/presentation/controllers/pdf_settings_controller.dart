import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsathi/features/photo_to_pdf/data/models/pdf_settings_model.dart';
import 'package:docsathi/features/photo_to_pdf/data/repositories/pdf_settings_repository.dart';

final pdfSettingsRepositoryProvider = Provider(
  (ref) => PdfSettingsRepository(),
);

final pdfSettingsProvider =
    NotifierProvider<PdfSettingsNotifier, PdfSettingsModel>(() {
      return PdfSettingsNotifier();
    });

class PdfSettingsNotifier extends Notifier<PdfSettingsModel> {
  @override
  PdfSettingsModel build() {
    return ref.read(pdfSettingsRepositoryProvider).getSettings();
  }

  Future<void> updateSettings({
    String? pageSize,
    String? orientation,
    String? margin,
    ImageQuality? imageQuality,
    String? password,
    String? watermarkText,
    Color? watermarkColor,
    double? watermarkOpacity,
    double? watermarkSize,
    double? watermarkAngle,
    bool? showPageNumbers,
    Color? backgroundColor,
  }) async {
    final newSettings = state.copyWith(
      pageSize: pageSize,
      orientation: orientation,
      margin: margin,
      imageQuality: imageQuality,
      password: password,
      watermarkText: watermarkText,
      watermarkColor: watermarkColor,
      watermarkOpacity: watermarkOpacity,
      watermarkSize: watermarkSize,
      watermarkAngle: watermarkAngle,
      showPageNumbers: showPageNumbers,
      backgroundColor: backgroundColor,
    );
    state = newSettings;
    await ref.read(pdfSettingsRepositoryProvider).saveSettings(newSettings);
  }
}
