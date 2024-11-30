import 'dart:math';
import 'package:flutter/material.dart';
import 'package:timea/common/widgets/ball_physics.dart';

class BallPainter extends CustomPainter {
  final List<BallPhysics> balls;

  BallPainter(this.balls);

  @override
  void paint(Canvas canvas, Size size) {
    for (final ball in balls) {
      // 그림자 추가
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2) // 그림자 색상
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3); // 블러 효과
      canvas.drawCircle(
          ball.position + const Offset(0, 0), ball.radius, shadowPaint);

      // 공 그리기 (랜덤 반구/흰색 반구)
      canvas.save();
      canvas.translate(ball.position.dx, ball.position.dy);
      canvas.rotate(ball.rotation);

      final rect =
          Rect.fromCircle(center: const Offset(0, 0), radius: ball.radius);
      canvas.drawArc(rect, -pi / 2, pi, true, Paint()..color = ball.color);

      final whitePaint = Paint()..color = Colors.white;
      canvas.drawArc(rect, pi / 2, pi, true, whitePaint);

      canvas.restore();

      // 광원 효과 추가 (Radial Gradient)
      final lightPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.2), // 밝은 중심
            Colors.transparent, // 가장자리
          ],
          stops: const [0.2, 1.0],
        ).createShader(
            Rect.fromCircle(center: ball.position, radius: ball.radius));
      canvas.drawCircle(ball.position, ball.radius, lightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
