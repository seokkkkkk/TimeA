import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:simple_shadow/simple_shadow.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    User? user = FirebaseAuth.instance.currentUser;

    await Future.delayed(const Duration(seconds: 2));

    if (user == null) {
      Get.offAllNamed('/login');
    } else {
      Get.offAllNamed('/');
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
          ],
        ),
      ),
    );
  }
}
