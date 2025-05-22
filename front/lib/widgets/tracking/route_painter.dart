// route_painter.dart: 등산로 시각화를 위한 커스텀 페인터
// - 산 등산로를 시각적으로 표현
// - 선택된 등산로 강조 표시

import 'package:flutter/material.dart';

// 등산로 시각화를 위한 커스텀 페인터
class RoutePainter extends CustomPainter {
  final List<Map<String, dynamic>> routes;
  final int selectedIndex;

  RoutePainter({
    required this.routes,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // 산 정상 표시
    final titlePaint = TextPainter(
      text: const TextSpan(
        text: '산 정상',
        style: TextStyle(
          fontSize: 14,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePaint.layout();
    titlePaint.paint(canvas, Offset(size.width / 2 - titlePaint.width / 2, 10));

    // 등산로 그리기
    if (routes.isEmpty) return;

    final paths = [
      Path()
        ..moveTo(40, size.height - 20)
        ..lineTo(80, 40),
      Path()
        ..moveTo(size.width / 2, size.height - 20)
        ..lineTo(size.width / 2 + 20, 40),
      Path()
        ..moveTo(size.width - 40, size.height - 20)
        ..lineTo(size.width - 80, 40),
    ];

    // 등산로 경로
    for (int i = 0; i < routes.length && i < paths.length; i++) {
      final route = routes[i];
      if (route['color'] == null) continue;

      final pathPaint = Paint()
        ..color = route['color']
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == selectedIndex ? 4 : 2;

      canvas.drawPath(paths[i], pathPaint);
    }

    // 미션형 표시
    if (routes.isNotEmpty) {
      final missionPaint = TextPainter(
        text: const TextSpan(
          text: '미션형 등산로',
          style: TextStyle(
            fontSize: 12,
            color: Colors.pink,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      missionPaint.layout();
      missionPaint.paint(canvas, Offset(20, size.height / 2));
    }

    // 선택된 경로 표시
    if (selectedIndex >= 0 && selectedIndex < routes.length) {
      final selectedRoute = routes[selectedIndex];
      if (selectedRoute['color'] != null) {
        final routeLabel = TextPainter(
          text: TextSpan(
            text: '선택한 등산로',
            style: TextStyle(
              fontSize: 12,
              color: selectedRoute['color'],
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        routeLabel.layout();
        routeLabel.paint(canvas,
            Offset(size.width - routeLabel.width - 10, size.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
