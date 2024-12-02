import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class EnvelopeAnimation extends StatefulWidget {
  const EnvelopeAnimation({super.key});

  @override
  State<EnvelopeAnimation> createState() => _EnvelopeAnimationState();
}

class _EnvelopeAnimationState extends State<EnvelopeAnimation>
    with SingleTickerProviderStateMixin {
  bool _isAnimating = false; // 편지봉투 애니메이션 상태
  bool _showMessage = false; // 메시지 표시 상태
  late AnimationController _logoShakeController; // 로고 흔들림 애니메이션 컨트롤러
  late Animation<double> _shakeAnimation;
  double _envelopeScale = 1.0; // 편지봉투 크기 애니메이션

  @override
  void initState() {
    super.initState();

    // 로고 흔들림 애니메이션 초기화
    _logoShakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..addListener(() {
        setState(() {});
      });

    _shakeAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _logoShakeController, curve: Curves.elasticIn),
    );

    // 편지봉투 애니메이션 시작
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isAnimating = true;
        _envelopeScale = 0.5; // 크기를 줄이기 시작
      });
    });

    // 편지봉투 애니메이션 완료 후 로고 흔들림 시작 및 메시지 표시
    Future.delayed(const Duration(seconds: 4), () {
      _logoShakeController.repeat(reverse: true);
      Future.delayed(const Duration(seconds: 1), () {
        _logoShakeController.stop();
        setState(() {
          _showMessage = true;
        });
      });

      // 전체 애니메이션 완료 후 페이지 닫기
      Future.delayed(const Duration(seconds: 3), () {
        Navigator.pop(context);
        Get.offNamed('/home');
      });
    });
  }

  @override
  void dispose() {
    _logoShakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 편지봉투 이미지 (위치 및 크기 애니메이션 적용)
          AnimatedPositioned(
            duration: const Duration(seconds: 3),
            curve: Curves.easeInOut,
            top: _isAnimating ? size.height * 0.38 : size.height * 0.8,
            left: _isAnimating ? size.width * 0.5 - 50 : size.width * 0.1,
            child: AnimatedScale(
              scale: _envelopeScale,
              duration: const Duration(seconds: 3),
              curve: Curves.easeInOut,
              child: Image.asset(
                'assets/images/envelope.png',
                width: 100,
                height: 100,
              ),
            ),
          ),
          // 로고 이미지 (흔들림 애니메이션 적용)
          Positioned(
            top: size.height * 0.3,
            child: Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: Image.asset(
                'assets/icons/logo.png',
                width: 300,
                height: 300,
              ),
            ),
          ),
          // 메시지 표시
          if (_showMessage)
            Positioned(
              bottom: 50,
              child: AnimatedOpacity(
                opacity: _showMessage ? 1.0 : 0.0,
                duration: const Duration(seconds: 2),
                child: const Text(
                  '당신의 기억이 캡슐에\n성공적으로 저장되었습니다!',
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
    );
  }
}
