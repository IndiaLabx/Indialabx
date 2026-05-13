import 'package:flutter/material.dart';
import 'package:docsathi/features/photo_to_pdf/data/models/pdf_settings_model.dart';
import 'package:docsathi/main.dart'; // import global sharedPreferences instance

class PdfSettingsRepository {
  static const String _pageSizeKey = 'pdf_setting_page_size';
  static const String _orientationKey = 'pdf_setting_orientation';
  static const String _marginKey = 'pdf_setting_margin';
  static const String _imageQualityKey = 'pdf_setting_image_quality';
  static const String _showPageNumbersKey = 'pdf_setting_show_page_numbers';

  // We don't persist password or watermark text across app restarts usually,
  // but we can persist the preferences for watermark styling.
  static const String _watermarkColorValueKey = 'pdf_setting_watermark_color';
  static const String _watermarkOpacityKey = 'pdf_setting_watermark_opacity';
  static const String _watermarkSizeKey = 'pdf_setting_watermark_size';
  static const String _watermarkAngleKey = 'pdf_setting_watermark_angle';
  static const String _backgroundColorValueKey = 'pdf_setting_background_color';

  PdfSettingsModel getSettings() {
    final qualityIndex =
        sharedPreferences.getInt(_imageQualityKey) ?? ImageQuality.medium.index;
    final quality = ImageQuality.values.length > qualityIndex
        ? ImageQuality.values[qualityIndex]
        : ImageQuality.medium;

    return PdfSettingsModel(
      pageSize: sharedPreferences.getString(_pageSizeKey) ?? 'A4',
      orientation: sharedPreferences.getString(_orientationKey) ?? 'Portrait',
      margin: sharedPreferences.getString(_marginKey) ?? 'None',
      imageQuality: quality,
      showPageNumbers: sharedPreferences.getBool(_showPageNumbersKey) ?? false,
      watermarkColor: Color(
        sharedPreferences.getInt(_watermarkColorValueKey) ??
            Colors.grey.toARGB32(),
      ),
      watermarkOpacity:
          sharedPreferences.getDouble(_watermarkOpacityKey) ?? 0.3,
      watermarkSize: sharedPreferences.getDouble(_watermarkSizeKey) ?? 40.0,
      watermarkAngle: sharedPreferences.getDouble(_watermarkAngleKey) ?? 45.0,
      backgroundColor: Color(
        sharedPreferences.getInt(_backgroundColorValueKey) ?? Colors.white.toARGB32(),
      ),
    );
  }

  Future<void> saveSettings(PdfSettingsModel settings) async {
    await sharedPreferences.setString(_pageSizeKey, settings.pageSize);
    await sharedPreferences.setString(_orientationKey, settings.orientation);
    await sharedPreferences.setString(_marginKey, settings.margin);
    await sharedPreferences.setInt(
      _imageQualityKey,
      settings.imageQuality.index,
    );
    await sharedPreferences.setBool(
      _showPageNumbersKey,
      settings.showPageNumbers,
    );
    await sharedPreferences.setInt(
      _watermarkColorValueKey,
      settings.watermarkColor.toARGB32(),
    );
    await sharedPreferences.setDouble(
      _watermarkOpacityKey,
      settings.watermarkOpacity,
    );
    await sharedPreferences.setDouble(
      _watermarkSizeKey,
      settings.watermarkSize,
    );
    await sharedPreferences.setDouble(
      _watermarkAngleKey,
      settings.watermarkAngle,
    );
    await sharedPreferences.setInt(
      _backgroundColorValueKey,
      settings.backgroundColor.toARGB32(),
    );
  }
}
