import 'dart:math';
import 'dart:ui';

class BallPhysics {
  final double radius;
  Offset position;
  Offset velocity;
  double angularVelocity = 0.0; // 각속도
  double rotation;
  final Color color;

  static const double gravity = 80.0; // 중력 가속도
  static const double friction = 0.98; // 마찰 계수
  static const double restitution = 0.8; // 반발 계수
  static const double maxVelocity = 500.0; // 최대 속도 제한

  BallPhysics._internal({
    required this.radius,
    required this.position,
    required this.velocity,
    required this.rotation,
    required this.color,
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
      rotation: Random().nextDouble() * 2 * pi,
      color: _getRandomColor(),
    );
  }

  static Color _getRandomColor() {
    const predefinedColors = [
      Color(0xFFFFE4A3),
      Color(0xFFFFF4E0),
      Color(0xFFFFCC66),
      Color(0xFFFFD8C2),
      Color(0xFFD9D9D9),
    ];
    final random = Random();
    return predefinedColors[random.nextInt(predefinedColors.length)];
  }

  void update(double deltaTime, double screenWidth, double bottomLimit) {
    // 중력 적용
    velocity = Offset(velocity.dx, velocity.dy + gravity * deltaTime);

    // 속도 제한
    velocity = Offset(
      velocity.dx.clamp(-maxVelocity, maxVelocity),
      velocity.dy.clamp(-maxVelocity, maxVelocity),
    );

    // 마찰 적용
    velocity *= friction;

    // 위치 업데이트
    position += velocity * deltaTime;

    // 경계 처리
    if (position.dy > bottomLimit - radius) {
      position = Offset(position.dx, bottomLimit - radius);
      velocity = Offset(velocity.dx, -velocity.dy * restitution);
    }

    if (position.dx - radius < 0) {
      position = Offset(radius, position.dy);
      velocity = Offset(-velocity.dx * restitution, velocity.dy);
    } else if (position.dx + radius > screenWidth) {
      position = Offset(screenWidth - radius, position.dy);
      velocity = Offset(-velocity.dx * restitution, velocity.dy);
    }

    // 회전 업데이트
    angularVelocity = velocity.dx / radius;
    rotation += angularVelocity * deltaTime;
  }

  void handleCollision(BallPhysics other) {
    final distance = (position - other.position).distance;

    if (distance < radius * 2) {
      final overlap = radius * 2 - distance;
      final direction = (position - other.position).normalize();

      // 위치 조정
      final totalMass = radius + other.radius;
      final selfAdjustment = overlap * (other.radius / totalMass);
      final otherAdjustment = overlap * (radius / totalMass);

      position += direction * selfAdjustment;
      other.position -= direction * otherAdjustment;

      // 속도 교환 및 충격량 계산
      final relativeVelocity = velocity - other.velocity;
      final impactSpeed = relativeVelocity.dot(direction);

      if (impactSpeed < 0) {
        final impulse = (2 * impactSpeed) / (radius + other.radius);

        velocity -= direction * impulse * other.radius * restitution;
        other.velocity += direction * impulse * radius * restitution;
      }
    }
  }
}

extension Normalize on Offset {
  Offset normalize() {
    final length = distance;
    return length == 0 ? this : this / length;
  }
}

extension OffsetExtensions on Offset {
  double dot(Offset other) {
    return dx * other.dx + dy * other.dy;
  }

  Offset operator *(double scalar) {
    return Offset(dx * scalar, dy * scalar);
  }
}
