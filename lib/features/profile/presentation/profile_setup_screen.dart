import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timea/common/widgets/app_bar.dart';
import 'package:timea/common/widgets/snack_bar_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timea/core/services/firebase_auth_service.dart';
import 'package:timea/core/services/firestore_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ProfileSetupScreenState createState() => ProfileSetupScreenState();
}

class ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nicknameController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();

  // 고정된 프로필 이미지 URL
  final String _profileImageUrl =
      "https://cdn.midjourney.com/283362b3-5af8-47e3-b6fe-f46742be000f/0_1.png";

  // 프로필 저장
  Future<void> _saveProfile() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && _nicknameController.text.isNotEmpty) {
      try {
        await FirestoreService.saveUserProfile(
          user: currentUser,
          nickname: _nicknameController.text,
          profileImage: _profileImageUrl,
        );
        Get.offAllNamed('/'); // 프로필 저장 후 홈 화면으로 이동
      } catch (e) {
        SnackbarUtil.showError('프로필 저장 실패', e.toString());
      }
    } else {
      SnackbarUtil.showError('닉네임을 입력해주세요.', '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TimeAppBar(title: '프로필 설정'),
      body: Padding(
        padding: const EdgeInsets.all(64.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(
                  '서비스 이용을 위해\n프로필 설정을 완료해주세요.',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // 프로필 이미지와 사진 아이콘
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(_profileImageUrl),
                      radius: 80,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // 닉네임 입력 필드
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  child: TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: '닉네임',
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // 프로필 설정 완료 버튼
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('프로필 설정 완료하기'),
            ),
          ],
        ),
      ),
    );
  }
}
