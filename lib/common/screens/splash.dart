import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timea/core/services/firebase_auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    User? user = FirebaseAuth.instance.currentUser;

    await Future.delayed(const Duration(seconds: 2)); // 스플래시 지연 시간

    if (user == null) {
      // 로그인 페이지로 이동
      Get.offAllNamed('/login');
    } else {
      // Firestore에서 사용자 데이터 확인
      DocumentSnapshot userDoc =
          await _authService.getUserFromFirestore(user.uid);

      if (!userDoc.exists) {
        // 프로필 설정 페이지로 이동
        Get.offAllNamed('/profileSetup');
      } else {
        // 홈 화면으로 이동
        Get.offAllNamed('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 및 로딩 인디케이터
            SimpleShadow(
              opacity: 0.8,
              color: theme.colorScheme.primary,
              offset: const Offset(0, 0),
              sigma: 50,
              child: Image.asset(
                'assets/icons/logo.png',
                width: 240,
                height: 240,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(), // 로딩 인디케이터 추가
          ],
        ),
      ),
    );
  }
}
