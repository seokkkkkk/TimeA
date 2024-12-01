import 'dart:math';
import 'dart:ui';

class BallPhysics {
  final String title;
  final double radius;
  Offset position;
  Offset velocity;
  double angularVelocity = 0.0; // 각속도
  double rotation;
  final Color color;
  final DateTime date; // 날짜 속성 추가
  final Offset gpsCoordinates; // GPS 좌표 속성 추가
  bool isUnlocked = false; // 잠금 상태

  // 기존 상수 정의는 유지
  static const double baseGravity = 80.0;
  static const double friction = 0.98;
  static const double restitution = 0.8;
  static const double maxVelocity = 500.0;

  BallPhysics._internal({
    required this.title,
    required this.radius,
    required this.position,
    required this.velocity,
    required this.rotation,
    required this.color,
    required this.date,
    required this.gpsCoordinates,
    required this.isUnlocked,
  });

  factory BallPhysics({
    required String title,
    required double radius,
    required Offset position,
    required Offset velocity,
    required DateTime date,
    required Offset gpsCoordinates,
    bool isUnlocked = false,
  }) {
    return BallPhysics._internal(
      title: title,
      radius: radius,
      position: position,
      velocity: velocity,
      rotation: Random().nextDouble() * 2 * pi,
      color: _getRandomColor(),
      date: date,
      gpsCoordinates: gpsCoordinates,
      isUnlocked: isUnlocked,
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
    return predefinedColors[Random().nextInt(predefinedColors.length)];
  }

  void update(
    double deltaTime,
    double screenWidth,
    double bottomLimit,
    double topLimit,
    double gravityX,
    double gravityY,
  ) {
    // 기울기에 따른 중력 방향 적용
    velocity = Offset(
      velocity.dx + gravityX * baseGravity * deltaTime,
      velocity.dy + gravityY * baseGravity * deltaTime,
    );

    // 속도 제한
    velocity = Offset(
      velocity.dx.clamp(-maxVelocity, maxVelocity),
      velocity.dy.clamp(-maxVelocity, maxVelocity),
    );

    // 마찰 적용
    velocity *= friction;

    // 위치 업데이트
    position += velocity * deltaTime;

    // 경계 처리 (아래쪽)
    if (position.dy > bottomLimit - radius) {
      position = Offset(position.dx, bottomLimit - radius);
      velocity = Offset(velocity.dx, -velocity.dy * restitution);
    }

    // 경계 처리 (위쪽)
    if (position.dy - radius < topLimit) {
      position = Offset(position.dx, topLimit + radius);
      velocity = Offset(velocity.dx, -velocity.dy * restitution);
    }

    // 경계 처리 (왼쪽)
    if (position.dx - radius < 0) {
      position = Offset(radius, position.dy);
      velocity = Offset(-velocity.dx * restitution, velocity.dy);
    }
    // 경계 처리 (오른쪽)
    else if (position.dx + radius > screenWidth) {
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
