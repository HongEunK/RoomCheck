import 'package:flutter/material.dart';

class DetectionPainter extends CustomPainter {
  final List<dynamic> detections;
  final double scaleX;
  final double scaleY;

  DetectionPainter(this.detections,
      {required this.scaleX, required this.scaleY});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (var detection in detections) {
      // bbox가 null이 아니고 List 타입이며, 길이가 4인지 확인
      final bbox = detection['bbox'];
      if (bbox != null && bbox is List && bbox.length == 4) {
        final rect = Rect.fromLTRB(
          (bbox[0] as num).toDouble() * scaleX,
          (bbox[1] as num).toDouble() * scaleY,
          (bbox[2] as num).toDouble() * scaleX,
          (bbox[3] as num).toDouble() * scaleY,
        );

        canvas.drawRect(rect, paint);

        // 클래스 이름 표시
        textPainter.text = TextSpan(
          text: detection['class'] ?? 'unknown',
          style: const TextStyle(
            color: Colors.white,
            backgroundColor: Colors.red,
            fontSize: 12,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, rect.topLeft.translate(4, 4));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
