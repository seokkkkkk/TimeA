import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GuestLoginButton extends StatelessWidget {
  final VoidCallback onSignIn;

  const GuestLoginButton({super.key, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // 진한 회색
        color: const Color.fromARGB(255, 77, 75, 69),
        borderRadius: BorderRadius.circular(8), // 모서리 둥글게
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4), // 그림자 색상
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
              // 로고
              SvgPicture.asset(
                'assets/images/guest.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFD0D0D0),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 12), // 이미지와 텍스트 간 간격
              // 텍스트
              const Text(
                '게스트로 로그인',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD0D0D0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
