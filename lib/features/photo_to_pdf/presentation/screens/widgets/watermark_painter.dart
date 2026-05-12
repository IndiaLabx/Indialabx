import 'package:flutter/material.dart';
import 'dart:math' as math;

class WatermarkPainter extends CustomPainter {
  final String text;
  final Color color;
  final double opacity;
  final double size;
  final double angle;

  WatermarkPainter({
    required this.text,
    required this.color,
    required this.opacity,
    required this.size,
    required this.angle,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    if (text.isEmpty) return;

    final textStyle = TextStyle(
      color: color.withValues(alpha: opacity),
      fontSize: size,
      fontWeight: FontWeight.bold,
    );

    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(
      minWidth: 0,
      maxWidth: canvasSize.width,
    );

    canvas.save();
    canvas.translate(canvasSize.width / 2, canvasSize.height / 2);
    canvas.rotate(angle * math.pi / 180);

    final offset = Offset(-textPainter.width / 2, -textPainter.height / 2);
    textPainter.paint(canvas, offset);

    canvas.restore();
  }

  @override
  bool shouldRepaint(WatermarkPainter oldDelegate) {
    return oldDelegate.text != text ||
           oldDelegate.color != color ||
           oldDelegate.opacity != opacity ||
           oldDelegate.size != size ||
           oldDelegate.angle != angle;
  }
}
