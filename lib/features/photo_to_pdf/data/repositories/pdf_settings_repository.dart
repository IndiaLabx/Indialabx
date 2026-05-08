import 'package:docsathi/features/photo_to_pdf/data/models/pdf_settings_model.dart';
import 'package:docsathi/main.dart'; // import global sharedPreferences instance

class PdfSettingsRepository {
  static const String _pageSizeKey = 'pdf_setting_page_size';
  static const String _orientationKey = 'pdf_setting_orientation';
  static const String _marginKey = 'pdf_setting_margin';

  PdfSettingsModel getSettings() {
    return PdfSettingsModel(
      pageSize: sharedPreferences.getString(_pageSizeKey) ?? 'A4',
      orientation: sharedPreferences.getString(_orientationKey) ?? 'Portrait',
      margin: sharedPreferences.getString(_marginKey) ?? 'None',
    );
  }

  Future<void> saveSettings(PdfSettingsModel settings) async {
    await sharedPreferences.setString(_pageSizeKey, settings.pageSize);
    await sharedPreferences.setString(_orientationKey, settings.orientation);
    await sharedPreferences.setString(_marginKey, settings.margin);
  }
}
