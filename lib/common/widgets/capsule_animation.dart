import 'dart:async';
import 'package:flutter/material.dart';

class CapsuleAnimation extends StatefulWidget {
  const CapsuleAnimation({super.key});

  @override
  CapsuleAnimationState createState() => CapsuleAnimationState();
}

class CapsuleAnimationState extends State<CapsuleAnimation>
    with SingleTickerProviderStateMixin {
  int _currentImageIndex = 0;
  late Timer _timer;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _showMessage = false;

  final List<String> _images = [
    'assets/images/locked-ball.png',
    'assets/images/unlockable-ball.png',
    'assets/images/unlocked-ball.png',
  ];

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);

    _shakeAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentImageIndex < _images.length - 1) {
        setState(() {
          _currentImageIndex++;
        });
      }

      if (_currentImageIndex == _images.length - 1) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showMessage = true;
            });
          }
        });

        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });

        _timer.cancel();
        _shakeController.stop();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (int i = 0; i < _images.length; i++)
              AnimatedOpacity(
                duration: const Duration(seconds: 2),
                opacity: _currentImageIndex == i ? 1.0 : 0.0,
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                          _currentImageIndex == i ? _shakeAnimation.value : 0,
                          0),
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(128),
                    child: Image.asset(
                      _images[i],
                      fit: BoxFit.contain,
                      width: 300,
                      height: 300,
                    ),
                  ),
                ),
              ),
            // 메시지 표시
            if (_showMessage)
              Positioned(
                bottom: 10,
                child: AnimatedOpacity(
                  opacity: _showMessage ? 1.0 : 0.0,
                  duration: const Duration(seconds: 2),
                  child: const Text(
                    '기억 캡슐의 잠금이\n성공적으로 해제되었습니다!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
