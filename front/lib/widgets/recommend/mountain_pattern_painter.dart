import 'package:flutter/material.dart';

class MountainPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    final path = Path();
    
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.3, size.height * 0.4);
    path.lineTo(size.width * 0.5, size.height * 0.6);
    path.lineTo(size.width * 0.7, size.height * 0.3);
    path.lineTo(size.width, size.height * 0.6);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}