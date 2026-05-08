import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsathi/features/photo_to_pdf/data/models/pdf_settings_model.dart';
import 'package:docsathi/features/photo_to_pdf/data/repositories/pdf_settings_repository.dart';

final pdfSettingsRepositoryProvider = Provider((ref) => PdfSettingsRepository());

final pdfSettingsProvider = NotifierProvider<PdfSettingsNotifier, PdfSettingsModel>(() {
  return PdfSettingsNotifier();
});

class PdfSettingsNotifier extends Notifier<PdfSettingsModel> {
  @override
  PdfSettingsModel build() {
    return ref.read(pdfSettingsRepositoryProvider).getSettings();
  }

  Future<void> updateSettings({String? pageSize, String? orientation, String? margin}) async {
    final newSettings = PdfSettingsModel(
      pageSize: pageSize ?? state.pageSize,
      orientation: orientation ?? state.orientation,
      margin: margin ?? state.margin,
    );
    state = newSettings;
    await ref.read(pdfSettingsRepositoryProvider).saveSettings(newSettings);
  }
}
