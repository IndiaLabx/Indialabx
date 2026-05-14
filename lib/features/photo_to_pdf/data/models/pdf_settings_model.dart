import 'package:flutter/material.dart';

enum ImageQuality { low, medium, high, original }

class PdfSettingsModel {
  final String pageSize;
  final String orientation;
  final String margin;
  final ImageQuality imageQuality;
  final String? password;
  final String? watermarkText;
  final Color watermarkColor;
  final double watermarkOpacity;
  final double watermarkSize;
  final double watermarkAngle;
  final bool showPageNumbers;
  final Color backgroundColor;
  final String imageFit;

  PdfSettingsModel({
    required this.pageSize,
    required this.orientation,
    required this.margin,
    this.imageQuality = ImageQuality.medium,
    this.password,
    this.watermarkText,
    this.watermarkColor = Colors.grey,
    this.watermarkOpacity = 0.3,
    this.watermarkSize = 40.0,
    this.watermarkAngle = 45.0,
    this.showPageNumbers = false,
    this.backgroundColor = Colors.white,
    this.imageFit = 'Contain',
  });

  PdfSettingsModel copyWith({
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
    String? imageFit,
  }) {
    return PdfSettingsModel(
      pageSize: pageSize ?? this.pageSize,
      orientation: orientation ?? this.orientation,
      margin: margin ?? this.margin,
      imageQuality: imageQuality ?? this.imageQuality,
      password: password ?? this.password,
      watermarkText: watermarkText ?? this.watermarkText,
      watermarkColor: watermarkColor ?? this.watermarkColor,
      watermarkOpacity: watermarkOpacity ?? this.watermarkOpacity,
      watermarkSize: watermarkSize ?? this.watermarkSize,
      watermarkAngle: watermarkAngle ?? this.watermarkAngle,
      showPageNumbers: showPageNumbers ?? this.showPageNumbers,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      imageFit: imageFit ?? this.imageFit,
    );
  }
}
