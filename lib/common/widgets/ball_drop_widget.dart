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
    _balls.clear(); // 공을 재초기화
    for (int i = 0; i < ballCount; i++) {
      _balls.add(
        BallPhysics(
          radius: ballRadius,
          position: Offset(
            Random().nextDouble() * 300, // Random x position
            Random().nextDouble() * 50, // Random y position
          ),
          velocity: Offset(
            (Random().nextDouble() - 0.5) * 200, // Random x velocity
            Random().nextDouble() * 200, // Random y velocity
          ),
        ),
      );
    }
  }

  @override
  void didUpdateWidget(covariant BallDropWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ballCount != oldWidget.ballCount) {
      ballCount = widget.ballCount;
      _initializeBalls(); // 새 공 개수에 맞게 재초기화
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
