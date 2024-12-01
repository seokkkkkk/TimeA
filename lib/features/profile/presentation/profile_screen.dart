import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timea/common/widgets/app_bar.dart';
import 'package:timea/core/services/firebase_auth_service.dart';
import 'package:timea/core/services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _profileImageUrl;
  String? _nickname;
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // Firestore에서 프로필 데이터 로드
  Future<void> _loadProfileData() async {
    if (_currentUser != null) {
      try {
        final userDoc = await FirestoreService.getUserProfile(_currentUser.uid);

        if (userDoc != null) {
          setState(() {
            _profileImageUrl = userDoc['profileImage'] as String?;
            _nickname = userDoc['nickname'] as String?;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 데이터를 불러오지 못했습니다: $e')),
        );
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authService = FirebaseAuthService();
    try {
      await authService.logout();
      Get.offAllNamed('/login');
    } catch (e) {
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
            // 프로필 이미지
            CircleAvatar(
              radius: 50,
              backgroundImage: _profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : const AssetImage('assets/icons/logo.png') as ImageProvider,
            ),
            const SizedBox(height: 12),
            // 닉네임과 수정 버튼
            Column(
              children: [
                Text(
                  _nickname ?? '',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 1),
                GestureDetector(
                  onTap: () {
                    // /profileSetup 페이지로 이동
                    Get.toNamed('/profileSetup');
                  },
                  child: const Text(
                    '프로필 수정',
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
            // 약관 및 로그아웃
            ListTile(
              title: const Text(
                '약관 및 개인정보',
                style: TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(255, 97, 97, 97),
                    fontWeight: FontWeight.bold),
              ),
              onTap: () {
                // 약관 페이지로 이동
              },
            ),
            ListTile(
              title: const Text(
                '로그아웃',
                style: TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(255, 97, 97, 97),
                    fontWeight: FontWeight.bold),
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
