import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:timea/common/widgets/app_bar.dart';
import 'package:timea/core/services/firebase_auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final authService = FirebaseAuthService();
    try {
      await authService.logout(); // 로그아웃 처리
      Get.offAllNamed('/login'); // 로그아웃 후 로그인 화면으로 이동
    } catch (e) {
      // 에러 발생 시 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TimeAppBar(title: '프로필 🧑‍💼'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 프로필 이미지와 수정 버튼 (Stack으로 구성)
            Stack(
              alignment: Alignment.center,
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage(
                      'assets/icons/logo.png'), // Replace with your image asset path
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to profile image edit screen
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFD9D9D9),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4.0),
                      child: const Icon(
                        Icons.photo,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 닉네임과 수정 버튼 (Row로 구성)
            Column(
              children: [
                const Text(
                  '닉네임',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 1),
                GestureDetector(
                  onTap: () {
                    // Navigate to nickname edit screen
                  },
                  child: const Text(
                    '닉네임 변경',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFC0C0C0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // D-DAY 임박 기억 캡슐 리스트
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '곧 만날 기억 캡슐',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: PageView.builder(
                itemCount: 5,
                controller: PageController(viewportFraction: 0.6),
                itemBuilder: (context, index) {
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    color: Colors.white,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '캡슐 제목 $index',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '2024년 11월 30일의 기억',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'D-6',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.red,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // 내가 저장한 기억 캡슐 리스트
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '되찾은 기억 캡슐',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: PageView.builder(
                itemCount: 5,
                controller: PageController(viewportFraction: 0.6),
                itemBuilder: (context, index) {
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    color: Colors.white,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '캡슐 제목 $index',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '2024년 11월 28일의 기억',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'D-8',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.red,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // 약관 및 로그아웃
            ListTile(
              title: const Text(
                '약관 및 개인정보',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                // Navigate to terms and conditions
              },
            ),
            ListTile(
              title: const Text(
                '로그아웃',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                _handleLogout(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
