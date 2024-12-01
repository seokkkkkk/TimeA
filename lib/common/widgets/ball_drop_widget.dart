import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timea/core/controllers/geolocation_controller.dart';
import 'dart:math';
import 'ball_physics.dart';
import 'package:timea/common/widgets/ball_painter.dart';

class BallDropWidget extends StatefulWidget {
  final List<Map<String, dynamic>> capsules;
  const BallDropWidget({super.key, required this.capsules});

  @override
  State<BallDropWidget> createState() => _BallDropWidgetState();
}

class _BallDropWidgetState extends State<BallDropWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final geolocationController = Get.find<GeolocationController>();
  late int ballCount;
  final List<BallPhysics> _balls = [];
  final double ballRadius = 30.0;
  double screenWidth = 0.0;
  double screenHeight = 0.0;
  double bottomLimit = 0.0;
  double topLimit = 0.0;

  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription? _accelerometerSubscription;

  // 기울기 데이터 저장
  double gravityX = 0.0;
  double gravityY = 1.0;

  // GPS 및 방향 데이터
  Position? get currentPosition => geolocationController.currentPosition.value;
  double? heading;

  @override
  void initState() {
    super.initState();
    ballCount = widget.capsules.length;

    _initializeBalls(widget.capsules);

    // 가속도 센서 구독
    _listenToAccelerometer();

    // 방향 정보 추적
    _trackHeading();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(() {
      if (!mounted) return;
      setState(() {
        const deltaTime = 1 / 24;
        for (final ball in _balls) {
          ball.update(deltaTime, screenWidth, bottomLimit, topLimit, -gravityX,
              gravityY);
        }

        for (int i = 0; i < _balls.length; i++) {
          for (int j = i + 1; j < _balls.length; j++) {
            _balls[i].handleCollision(_balls[j]);
          }
        }
      });
    });
  }

  void _listenToAccelerometer() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (!mounted) return;
      setState(() {
        gravityX = event.x / 10; // 민감도 조절
        gravityY = event.y / 10; // 민감도 조절
      });
    });
  }

  void _initializeBalls(capsules) {
    _balls.clear();
    for (final capsule in capsules) {
      _addNewBall(capsule);
    }
  }

  void _addNewBall(capsule) {
    final randomOffsetX = (Random().nextDouble() - 0.5) * 50;
    final randomOffsetY = Random().nextDouble() * 50 + 100;

    final newBall = BallPhysics(
      title: capsule['title'],
      radius: ballRadius,
      position: Offset(
        Random().nextDouble() * screenWidth,
        Random().nextDouble() * 100,
      ),
      velocity: Offset(randomOffsetX, randomOffsetY),
      date: (capsule['canUnlockedAt'] as Timestamp).toDate(),
      gpsCoordinates: Offset(
        capsule['location'].longitude,
        capsule['location'].latitude,
      ),
    );

    _balls.add(newBall);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    const navBarHeight = kBottomNavigationBarHeight;
    bottomLimit = screenHeight - navBarHeight - 150;
    topLimit = 0;
  }

  void _trackHeading() {
    double magX = 0.0, magY = 0.0, magZ = 0.0;
    double accX = 0.0, accY = 0.0, accZ = 0.0;

    _magnetometerSubscription = magnetometerEventStream().listen((event) {
      magX = event.x;
      magY = event.y;
      magZ = event.z;

      if (accX != 0.0 || accY != 0.0 || accZ != 0.0) {
        final correctedHeading =
            _calculateCorrectedHeading(magX, magY, magZ, accX, accY, accZ);
        if (!mounted) return;
        setState(() {
          heading = correctedHeading;
        });
      }
    });

    accelerometerEventStream().listen((event) {
      accX = event.x;
      accY = event.y;
      accZ = event.z;
    });
  }

  double _calculateCorrectedHeading(double magX, double magY, double magZ,
      double accX, double accY, double accZ) {
    final roll = atan2(accY, accZ);
    final pitch = atan(-accX / sqrt(accY * accY + accZ * accZ));

    final correctedX = magX * cos(pitch) + magZ * sin(pitch);
    final correctedY = magX * sin(roll) * sin(pitch) +
        magY * cos(roll) -
        magZ * sin(roll) * cos(pitch);

    return (atan2(correctedY, correctedX) * (180 / pi) + 360) % 360;
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    geolocationController.positionStream.value?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        final touchPoint = details.localPosition;
        for (final ball in _balls) {
          if ((touchPoint - ball.position).distance <= ballRadius) {
            _showBallDetails(ball);
            break;
          }
        }
        setState(() {
          _scatterBalls(touchPoint);
        });
      },
      child: CustomPaint(
        painter: BallPainter(_balls),
        child: Container(),
      ),
    );
  }

  void _scatterBalls(Offset touchPoint) {
    for (final ball in _balls) {
      final direction = (ball.position - touchPoint).normalize();
      final randomSpeed = Random().nextDouble() * 300 + 100;
      final newVelocity = direction * randomSpeed;

      ball.velocity = newVelocity;
    }
  }

  void _showBallDetails(BallPhysics ball) {
    print(currentPosition);
    print(heading);
    if (currentPosition == null || heading == null) {
      _showError("위치나 방향 정보를 가져오지 못했습니다.");
      return;
    }

    final locationDifference = calculateLocationDifference(ball.gpsCoordinates);
    final locationMessage = locationDifference ?? '위치 정보를 가져오는 중...';

    final isUnlockable = ball.date.isBefore(DateTime.now()) &&
        locationDifference != null &&
        locationDifference == '기억 캡슐의 위치입니다.';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(ball.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("날짜: ${ball.date}"),
              Text("위치 차이: $locationMessage"),
              Text("잠금 상태: ${ball.isUnlocked ? "해제됨" : "잠김"}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isUnlockable
                  ? () {
                      setState(() {
                        ball.isUnlocked = true;
                      });
                      Navigator.of(context).pop();
                    }
                  : null,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                  (states) => isUnlockable ? Colors.blue : Colors.grey,
                ),
                foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                  (states) => Colors.white,
                ),
              ),
              child: const Text("잠금 해제"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("확인"),
            ),
          ],
        );
      },
    );
  }

  String? calculateLocationDifference(Offset ballCoordinates) {
    if (currentPosition == null || heading == null) return null;

    final dx = ballCoordinates.dx - currentPosition!.longitude;
    final dy = ballCoordinates.dy - currentPosition!.latitude;
    final distance = sqrt(dx * dx + dy * dy) * 111000;

    if (distance <= 5) {
      return '기억 캡슐의 위치입니다.';
    }

    final angleToTarget = atan2(dy, dx) * 180 / pi;
    final relativeAngle = ((angleToTarget - heading!) + 360) % 360;

    String direction;
    if (relativeAngle >= 0 && relativeAngle < 45 || relativeAngle >= 315) {
      direction = '앞쪽';
    } else if (relativeAngle >= 45 && relativeAngle < 135) {
      direction = '오른쪽';
    } else if (relativeAngle >= 135 && relativeAngle < 225) {
      direction = '뒤쪽';
    } else {
      direction = '왼쪽';
    }

    if (distance >= 1000) {
      return '$direction으로 ${(distance / 1000).toStringAsFixed(1)}km';
    }

    return '$direction으로 ${distance.toStringAsFixed(1)}m';
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("오류"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }
}
