import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timea/common/widgets/app_bar.dart';
import 'package:timea/common/widgets/snack_bar_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timea/core/services/firebase_auth_service.dart';
import 'package:timea/core/services/firestore_service.dart';
import 'package:timea/features/home/service/capsule_service.dart';

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
  bool? isNicknameChecked;
  String? previousNickname; // 이전 닉네임을 저장

  @override
  void initState() {
    super.initState();
    isNicknameChecked = widget.backButtonVisible;
    _nicknameController.addListener(() {
      setState(() {
        isNicknameChecked = false; // 닉네임이 변경되면 다시 확인 필요
        if (_nicknameController.text.isEmpty) {
          isNicknameChecked = true; // 닉네임이 비어있으면 확인하지 않음
        }
      });
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> checkNickname() async {
    final nickname = _nicknameController.text.trim();

    if (nickname.isEmpty) {
      SnackbarUtil.showError('닉네임 입력 필요', '닉네임을 입력해주세요.');
      return;
    }

    if (previousNickname == nickname) {
      // 닉네임이 변경되지 않았으면 재확인하지 않음
      SnackbarUtil.showInfo('닉네임 변경 없음', '닉네임이 이전과 동일합니다.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final exists = await FirestoreService.isNicknameExists(nickname);
      if (exists) {
        SnackbarUtil.showError('닉네임 중복', '이미 사용 중인 닉네임입니다.');
        setState(() {
          isNicknameChecked = false;
        });
      } else {
        SnackbarUtil.showSuccess('사용 가능', '사용 가능한 닉네임입니다.');
        setState(() {
          isNicknameChecked = true;
          previousNickname = nickname; // 확인된 닉네임 저장
        });
      }
    } catch (e) {
      SnackbarUtil.showError('중복 확인 실패', e.toString());
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
        setState(() {
          isLoading = true;
        });
        try {
          final imageUrl = await CapsuleService().uploadImage(
              currentUser.uid, image,
              minHeight: 300, minWidth: 300);
          if (imageUrl != null) {
            setState(() {
              _profileImageUrl = imageUrl; // 업로드 성공 시 URL로 변경
            });
          }
        } catch (e) {
          SnackbarUtil.showError('이미지 업로드 실패', e.toString());
        } finally {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  Future<void> saveProfile() async {
    if (isLoading == true) {
      SnackbarUtil.showInfo('이미지 업로드 중', '프로필 이미지 업로드가 진행 중입니다.');
      return;
    }
    if (isSubmitting == true) {
      SnackbarUtil.showInfo('저장 중', '프로필 저장이 진행 중입니다.');
      return;
    }

    if (widget.backButtonVisible) {
      if (_nicknameController.text.isEmpty && _selectedImage == null) {
        SnackbarUtil.showError('입력 확인', '닉네임과 프로필 사진 중 하나 이상을 설정해야 합니다.');
        return;
      }
    } else {
      if (_nicknameController.text.isEmpty || _selectedImage == null) {
        SnackbarUtil.showError('입력 확인', '닉네임과 프로필 사진을 모두 설정해야 합니다.');
        return;
      }
    }

    if (_nicknameController.text.isNotEmpty && !isNicknameChecked!) {
      SnackbarUtil.showError('닉네임 확인', '닉네임 중복 확인이 필요합니다.');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('사용자 인증 정보가 없습니다.');
      }

      if (widget.backButtonVisible) {
        await FirestoreService.updateUserProfile(
          user: user,
          nickname: _nicknameController.text.trim(),
          profileImage: _profileImageUrl!,
        );
      } else {
        await FirebaseAuthService.saveUserToFirestore(
          user,
          _nicknameController.text.trim(),
          _profileImageUrl!,
        );
      }

      Get.offAllNamed('/');
      SnackbarUtil.showSuccess('프로필 저장 완료', '프로필이 성공적으로 저장되었습니다.');
    } catch (e) {
      SnackbarUtil.showError('프로필 저장 실패', e.toString());
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TimeAppBar(
        title: '프로필 설정',
        backButton: widget.backButtonVisible,
        notification: false,
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
                    decoration: InputDecoration(
                      labelText: '닉네임',
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        onPressed: isLoading ? null : checkNickname,
                        icon: const Icon(Icons.check),
                        tooltip: '중복 확인',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // 프로필 설정 완료 버튼
            ElevatedButton(
              onPressed: isSubmitting == true || !isNicknameChecked!
                  ? null
                  : saveProfile,
              child: const Text('프로필 설정 완료하기'),
            ),
          ],
        ),
      ),
    );
  }
}
