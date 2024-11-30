import 'dart:math';
import 'dart:ui';

class BallPhysics {
  final double radius;
  Offset position;
  Offset velocity;
  double angularVelocity = 0.0;
  double rotation;
  final Color color; // 공의 색상

  final double gravity = 100; // 중력 가속도 대폭 증가
  final double friction = 0.98; // 마찰 계수
  final double maxVelocity = 100.0; // 속도 상한

  BallPhysics._internal({
    required this.radius,
    required this.position,
    required this.velocity,
    required this.rotation,
    required this.color, // 생성자에 색상 추가
  });

  factory BallPhysics({
    required double radius,
    required Offset position,
    required Offset velocity,
  }) {
    return BallPhysics._internal(
      radius: radius,
      position: position,
      velocity: velocity,
      rotation: Random().nextDouble() * 2 * pi, // 무작위 회전 초기화
      color: _getRandomColor(), // 무작위 색상 초기화
    );
  }

  static Color _getRandomColor() {
    // 지정된 색상 배열
    const predefinedColors = [
      Color(0xFFFFE4A3),
      Color(0xFFFFF4E0),
      Color(0xFFFFCC66),
      Color(0xFFFFD8C2),
      Color(0xFFD9D9D9),
    ];

    // 무작위로 하나 선택
    final random = Random();
    return predefinedColors[random.nextInt(predefinedColors.length)];
  }

  void update(double deltaTime, double screenWidth, double bottomLimit) {
    // 중력을 강하게 적용
    velocity = Offset(velocity.dx, velocity.dy + gravity * deltaTime);

    // 속도 제한 (속도가 너무 커지지 않도록 제한)
    velocity = Offset(
      velocity.dx.clamp(-maxVelocity, maxVelocity),
      velocity.dy.clamp(-maxVelocity, maxVelocity),
    );

    // 마찰 적용
    velocity = Offset(velocity.dx * friction, velocity.dy * friction);

    // 위치 업데이트
    position += velocity * deltaTime;

    // 화면 경계 처리
    if (position.dy > bottomLimit - radius) {
      position = Offset(position.dx, bottomLimit - radius);
      velocity = Offset(velocity.dx, -velocity.dy * 0.7); // 반사 속도 감소
    }

    if (position.dx - radius < 0) {
      position = Offset(radius, position.dy);
      velocity = Offset(-velocity.dx * 0.7, velocity.dy);
    } else if (position.dx + radius > screenWidth) {
      position = Offset(screenWidth - radius, position.dy);
      velocity = Offset(-velocity.dx * 0.7, velocity.dy);
    }

    // 각속도와 회전 업데이트
    angularVelocity = velocity.dx / radius;
    rotation += angularVelocity * deltaTime;
  }

  // 충돌 처리
  void handleCollision(BallPhysics other) {
    final distance = (position - other.position).distance;

    if (distance < radius * 2) {
      final overlap = radius * 2 - distance;
      final direction = (position - other.position).normalize();

      position += direction * overlap / 2;
      other.position -= direction * overlap / 2;

      final tempVelocity = velocity;
      velocity = other.velocity;
      other.velocity = tempVelocity;
    }
  }
}

extension Normalize on Offset {
  Offset normalize() {
    final length = distance;
    return length == 0 ? this : this / length;
  }
}
