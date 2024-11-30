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
  late int ballCount; // `late`를 사용하여 초기화를 지연
  final List<BallPhysics> _balls = [];
  final double ballRadius = 30.0;
  double screenWidth = 0.0;
  double bottomLimit = 0.0;

  @override
  void initState() {
    super.initState();
    ballCount = widget.ballCount; // 여기에서 widget의 값을 초기화

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
    _balls.clear(); // 기존 공 목록 초기화
    for (int i = 0; i < ballCount; i++) {
      _addNewBall();
    }
  }

  void _addNewBall() {
    final newBall = BallPhysics(
      radius: ballRadius,
      position: Offset(
        Random().nextDouble() * screenWidth, // 화면 상단의 랜덤 x 위치
        0, // 새 공은 항상 화면 위에서 시작
      ),
      velocity: Offset(
        (Random().nextDouble() - 0.5) * 200, // 랜덤 x 속도
        Random().nextDouble() * 100, // 랜덤 y 속도
      ),
    );
    _balls.add(newBall);
  }

  @override
  void didUpdateWidget(covariant BallDropWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ballCount > oldWidget.ballCount) {
      final newBalls = widget.ballCount - oldWidget.ballCount;
      for (int i = 0; i < newBalls; i++) {
        _addNewBall();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    const navBarHeight =
        kBottomNavigationBarHeight; // BottomNavigationBar height
    bottomLimit = screenHeight - navBarHeight - 150; // Add padding
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BallPainter(_balls),
      child: Container(),
    );
  }
}
