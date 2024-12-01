import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';
import 'ball_physics.dart';
import 'package:timea/common/widgets/ball_painter.dart';

class BallDropWidget extends StatefulWidget {
  final int ballCount;
  const BallDropWidget({super.key, required this.ballCount});

  @override
  State<BallDropWidget> createState() => _BallDropWidgetState();
}

class _BallDropWidgetState extends State<BallDropWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int ballCount;
  final List<BallPhysics> _balls = [];
  final double ballRadius = 30.0;
  double screenWidth = 0.0;
  double bottomLimit = 0.0;

  // 기울기 데이터 저장
  double gravityX = 0.0;
  double gravityY = 1.0;

  @override
  void initState() {
    super.initState();
    ballCount = widget.ballCount;

    _initializeBalls();

    // 가속도 센서 구독
    _listenToAccelerometer();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(() {
      setState(() {
        const deltaTime = 1 / 24;
        for (final ball in _balls) {
          ball.update(deltaTime, screenWidth, bottomLimit, -gravityX,
              gravityY); // X축 반전
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
    accelerometerEventStream().listen((event) {
      setState(() {
        // 기울기 데이터를 정규화하여 사용
        gravityX = event.x / 10; // 민감도 조절
        gravityY = event.y / 10; // 민감도 조절
      });
    });
  }

  void _initializeBalls() {
    _balls.clear();
    for (int i = 0; i < ballCount; i++) {
      _addNewBall();
    }
  }

  void _addNewBall() {
    final randomOffsetX = (Random().nextDouble() - 0.5) * 50;
    final randomOffsetY = Random().nextDouble() * 50 + 100;

    final newBall = BallPhysics(
      id: _balls.length,
      radius: ballRadius,
      position: Offset(
        Random().nextDouble() * screenWidth,
        Random().nextDouble() * 100,
      ),
      velocity: Offset(randomOffsetX, randomOffsetY),
      date: DateTime.now().add(Duration(days: Random().nextInt(7))), // 랜덤 날짜
      gpsCoordinates: Offset(
        Random().nextDouble() * 100,
        Random().nextDouble() * 100,
      ),
    );

    _balls.add(newBall);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    const navBarHeight = kBottomNavigationBarHeight;
    bottomLimit = screenHeight - navBarHeight - 150;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        final touchPoint = details.localPosition;
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
}
