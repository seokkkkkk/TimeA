import 'package:flutter/material.dart';
import 'package:timea/common/widgets/ball_painter.dart';
import 'dart:math';
import 'ball_physics.dart';

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

  @override
  void initState() {
    super.initState();
    ballCount = widget.ballCount;

    _initializeBalls();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(() {
      setState(() {
        const deltaTime = 1 / 24;
        for (final ball in _balls) {
          ball.update(deltaTime, screenWidth, bottomLimit);
        }

        for (int i = 0; i < _balls.length; i++) {
          for (int j = i + 1; j < _balls.length; j++) {
            _balls[i].handleCollision(_balls[j]);
          }
        }
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
    final randomOffsetX = (Random().nextDouble() - 0.5) * 50; // x 방향 속도 범위 설정
    final randomOffsetY =
        Random().nextDouble() * 50 + 100; // y 방향 속도 범위 설정 (항상 아래쪽)

    final newBall = BallPhysics(
      radius: ballRadius,
      position: Offset(
        Random().nextDouble() * screenWidth, // 화면의 랜덤 위치
        Random().nextDouble() * 100, // 화면 상단 근처
      ),
      velocity: Offset(randomOffsetX, randomOffsetY), // 아래쪽으로 떨어지도록 초기 속도 설정
    );

    _balls.add(newBall);
  }

  void _scatterBalls(Offset touchPoint) {
    for (final ball in _balls) {
      final direction = (ball.position - touchPoint).normalize();
      final randomSpeed = Random().nextDouble() * 300 + 100; // 속도 범위 설정
      final newVelocity = direction * randomSpeed;

      ball.velocity = newVelocity; // 새로운 속도로 업데이트
    }
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
}
