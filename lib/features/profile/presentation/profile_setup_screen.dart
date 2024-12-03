import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timea/common/widgets/app_bar.dart';
import 'package:timea/common/widgets/snack_bar_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timea/core/services/firestore_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool backButtonVisible;
  const ProfileSetupScreen({super.key, this.backButtonVisible = false});

  @override
  ProfileSetupScreenState createState() => ProfileSetupScreenState();
}

class ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nicknameController = TextEditingController();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  String? _profileImageUrl; // 프로필 이미지 URL
  XFile? _selectedImage; // 선택한 이미지 파일
  bool? isSubmitting = false;
  bool isLoading = false;

  Future<String?> uploadImage(String userId, XFile image) async {
    setState(() {
      isLoading = true;
    });
    try {
      final storageRef = _storage.ref().child(
          'profile/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = await storageRef.putFile(File(image.path));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      SnackbarUtil.showError('이미지 업로드 실패', '이미지를 업로드하는 중 문제가 발생했습니다: $e');
      return null;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _profileImageUrl = image.path; // 로컬 경로 즉시 표시
      });

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // 업로드 비동기 처리
        uploadImage(currentUser.uid, image).then((uploadedUrl) {
          if (uploadedUrl != null) {
            setState(() {
              _profileImageUrl = uploadedUrl; // 업로드 완료 후 업데이트
            });
          }
        }).catchError((e) {
          SnackbarUtil.showError('이미지 업로드 실패', e.toString());
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      isSubmitting = true;
    });
    while (isLoading) {
      //기다리기 위한 루프
    }
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && _nicknameController.text.isNotEmpty) {
      try {
        await FirestoreService.updateUserProfile(
          user: currentUser,
          nickname: _nicknameController.text,
          profileImage: _profileImageUrl ?? '',
        );
        setState(() {
          isSubmitting = false;
        });
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
      appBar: TimeAppBar(
        title: '프로필 설정',
        backButton: widget.backButtonVisible,
      ),
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.all(64.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(
                  widget.backButtonVisible
                      ? '프로필 사진 또는 닉네임을\n수정할 수 있습니다.'
                      : '서비스 이용을 위해\n프로필 설정을 완료해주세요.',
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
                      backgroundImage: _selectedImage != null
                          ? FileImage(File(_selectedImage!.path)) // 로컬 이미지
                          : (_profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!) // 네트워크 이미지
                              : const AssetImage(
                                      'assets/images/default_avatar.png')
                                  as ImageProvider), // 기본 이미지
                      radius: 80,
                    ),
                    if (isLoading)
                      const Positioned.fill(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
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
              onPressed: isSubmitting == true
                  ? () {
                      SnackbarUtil.showInfo('저장중', '프로필을 업로드 중입니다.');
                    }
                  : _saveProfile,
              child: const Text('프로필 설정 완료하기'),
            ),
          ],
        ),
      ),
    );
  }
}
