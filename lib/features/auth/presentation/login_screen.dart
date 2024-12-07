import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:timea/core/services/firebase_auth_service.dart';
import 'package:timea/common/widgets/snack_bar_util.dart';
import 'package:timea/core/widgets/apple_login_button.dart';
import 'package:timea/core/widgets/guest_login_button.dart';
import 'package:timea/core/widgets/google_login_button.dart';
import 'package:timea/features/profile/presentation/profile_setup_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final FirebaseAuthService _authService = FirebaseAuthService();

  // Google Sign-In Handler
  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      UserCredential userCredential = await _authService.signInWithGoogle();
      if (userCredential.user != null) {
        User? currentUser = userCredential.user;
        DocumentSnapshot userDoc =
            await _authService.getUserFromFirestore(currentUser!.uid);

        // 사용자 정보가 없다면 프로필 설정 페이지로 이동
        if (!userDoc.exists) {
          Get.to(const ProfileSetupScreen(
            backButtonVisible: false,
          )); // 닉네임 및 프로필 설정 페이지로 이동
        } else {
          Get.offAllNamed('/');
        }
      }
    } catch (e) {
      SnackbarUtil.showError('Google 로그인 실패', e.toString());
    }
  }

  // Apple Sign-In Handler
  void _handleAppleSignIn(BuildContext context) async {
    try {
      UserCredential userCredential = await _authService.signInWithApple();
      if (userCredential.user != null) {
        User? currentUser = userCredential.user;
        DocumentSnapshot userDoc =
            await _authService.getUserFromFirestore(currentUser!.uid);

        // 사용자 정보가 없다면 프로필 설정 페이지로 이동
        if (!userDoc.exists) {
          Get.to(const ProfileSetupScreen(
            backButtonVisible: false,
          )); // 닉네임 및 프로필 설정 페이지로 이동
        } else {
          Get.offAllNamed('/');
        }
      }
    } catch (e) {
      SnackbarUtil.showError('Apple 로그인 실패', e.toString());

      print(e);
    }
  }

  // Guest Sign-In Handler
  Future<void> _handleGuestSignIn(BuildContext context) async {
    try {
      UserCredential userCredential = await _authService.signInAnonymously();
      if (userCredential.user != null) {
        User? currentUser = userCredential.user;
        DocumentSnapshot userDoc =
            await _authService.getUserFromFirestore(currentUser!.uid);

        // 사용자 정보가 없다면 프로필 설정 페이지로 이동
        if (!userDoc.exists) {
          Get.toNamed('/profileSetup'); // 닉네임 및 프로필 설정 페이지로 이동
        } else {
          Get.offAllNamed('/');
        }
      }
    } catch (e) {
      SnackbarUtil.showError('Guest 로그인 실패', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 120, 16, 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Logo with shadow effect
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
              Column(
                children: [
                  Text(
                    '순간을 추억하는 새로운 방법',
                    style: theme.textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '로그인하여 추억하기',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Google Login Button
                  GoogleLoginButton(
                    onSignIn: () => _handleGoogleSignIn(context),
                  ),
                  const SizedBox(height: 16),
                  // Apple Login Button
                  AppleLoginButton(
                    onSignIn: () => _handleAppleSignIn(context),
                  ),
                  const SizedBox(height: 16),
                  // Guest Login Button
                  GuestLoginButton(
                    onSignIn: () => _handleGuestSignIn(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
