import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GoogleLoginButton extends StatelessWidget {
  final VoidCallback onSignIn;

  const GoogleLoginButton({super.key, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Google 버튼 배경색
        borderRadius: BorderRadius.circular(8), // 모서리 둥글게
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // 그림자 색상
            offset: const Offset(0, 4), // 그림자 위치
            blurRadius: 8, // 그림자 흐림 정도
          ),
        ],
      ),
      child: MaterialButton(
        onPressed: onSignIn,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min, // 중앙 정렬을 위해 최소 크기로 설정
            children: [
              // 좌측 정렬된 Google 로고
              SvgPicture.asset(
                'assets/images/google.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 16), // 로고와 텍스트 간 간격
              const Text(
                'Google로 로그인',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
