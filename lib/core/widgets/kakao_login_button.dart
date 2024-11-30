import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // SVG 지원을 위한 패키지

class KakaoLoginButton extends StatelessWidget {
  final VoidCallback onSignIn;

  const KakaoLoginButton({super.key, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEE500), // 카카오 노란색
        borderRadius: BorderRadius.circular(12), // radius 설정
      ),
      child: MaterialButton(
        onPressed: onSignIn, // 클릭 이벤트
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
            children: [
              // 좌측 정렬된 카카오 로고
              SvgPicture.asset(
                'assets/images/kakao.svg', // SVG 파일 경로
                width: 18, // 심볼 너비
                height: 18, // 심볼 높이
              ),
              const SizedBox(width: 16), // 간격R
              // 중앙 정렬된 텍스트
              const Text(
                '카카오로 로그인',
                textAlign: TextAlign.center, // 텍스트 중앙 정렬
                style: TextStyle(
                  fontSize: 16, // 폰트 크기
                  fontWeight: FontWeight.w700, // 폰트 두께
                  color: Colors.black, // 검정색 텍스트
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
