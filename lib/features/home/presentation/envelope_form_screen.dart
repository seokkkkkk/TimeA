import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:timea/common/widgets/app_bar.dart';
import 'package:timea/common/widgets/envelope_animation.dart';
import 'package:timea/common/widgets/snack_bar_util.dart';
import 'package:timea/core/controllers/geolocation_controller.dart';
import 'package:timea/core/model/capsule.dart';
import 'package:timea/core/services/firebase_auth_service.dart';
import 'package:timea/core/services/firestore_service.dart';
import 'package:timea/features/home/service/capsule_service.dart';
import 'package:timea/features/map/presentation/map_screen.dart';

class EnvelopeFormScreen extends StatefulWidget {
  final Function(Capsule) onSubmit;
  final List<Capsule> capsules;

  const EnvelopeFormScreen(
      {super.key, required this.onSubmit, required this.capsules});

  @override
  State<EnvelopeFormScreen> createState() => _EnvelopeFormScreenState();
}

class _EnvelopeFormScreenState extends State<EnvelopeFormScreen> {
  final picker = ImagePicker();
  XFile? image;
  final _titleController = TextEditingController();
  final _textContentController = TextEditingController();
  final GeolocationController _geolocationController =
      Get.find<GeolocationController>();
  DateTime? openDate;
  bool isSubmitting = false;

  final FirebaseAuthService authService = FirebaseAuthService();
  final CapsuleService capsuleService = CapsuleService();

  String? userId;

  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> selectedFriends = [];

  @override
  void initState() {
    super.initState();
    fetchFriends();
    // 초기화 로직
    final currentUser = authService.auth.currentUser;
    if (currentUser != null) {
      userId = currentUser.uid;
    } else {
      SnackbarUtil.showError(
        '사용자 정보 없음',
        '로그인된 사용자가 없습니다. 로그인 후 다시 시도해주세요.',
      );
    }
  }

  Future<void> fetchFriends() async {
    try {
      friends = await FirestoreService.getFriends(); // Firestore에서 친구 목록 가져오기
      setState(() {});
    } catch (e) {
      SnackbarUtil.showError('에러', '친구 목록을 불러오지 못했습니다: $e');
    }
  }

  void selectFriend(Map<String, dynamic>? friend) {
    if (friend == null) return; // null 체크 추가
    if (selectedFriends.length >= 4) {
      SnackbarUtil.showInfo('제한', '최대 4명까지 선택할 수 있습니다.');
      return;
    }
    if (!selectedFriends.contains(friend)) {
      setState(() => selectedFriends.add(friend));
    }
  }

  void removeFriend(Map<String, dynamic> friend) {
    setState(() => selectedFriends.remove(friend));
  }

  Widget _buildFriendsDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '함께할 친구 선택',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          child: DropdownButtonFormField<Map<String, dynamic>>(
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            hint: const Text(
              '친구를 선택하세요 (최대 4명)',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            items: friends.map((friend) {
              return DropdownMenuItem(
                value: friend,
                child: Text(
                  friend['nickname'] ?? '이름 없음',
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: selectFriend,
            isDense: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFriends() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedFriends.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedFriends.map((friend) {
              return Chip(
                label: Text(friend['nickname'] ?? ''),
                deleteIcon: const Icon(Icons.cancel),
                onDeleted: () => removeFriend(friend),
                backgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _pickDateTime() async {
    DateTime now = DateTime.now();
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (date != null) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          openDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedImage = await picker.pickImage(source: ImageSource.camera);
      if (pickedImage != null) {
        setState(() {
          image = pickedImage;
        });
      } else {
        SnackbarUtil.showInfo('이미지 선택', '이미지를 선택하지 않았습니다.');
      }
    } catch (e) {
      SnackbarUtil.showError('에러', '이미지를 불러오는 중 문제가 발생했습니다: $e');
    }
  }

  void _removeImage() {
    setState(() {
      image = null;
    });
  }

  Widget _buildInputField(TextEditingController controller, String labelText) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Future<void> _handleSubmit(userId) async {
    if (isSubmitting) return;

    if (_titleController.text.isEmpty ||
        (_textContentController.text.isEmpty && image == null) ||
        openDate == null ||
        _geolocationController.currentPosition.value == null) {
      SnackbarUtil.showInfo('내용 입력 필요', '필수 항목을 모두 입력해주세요.');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final List<String> sharedWith =
        selectedFriends.map((friend) => friend['id'].toString()).toList();

    Get.to(() => const EnvelopeAnimation());

    try {
      final imageUrlFuture = image != null
          ? capsuleService.uploadImage(userId, image!, quality: 95)
          : Future.value(null);

      final imageUrl = await imageUrlFuture ?? '';

      final capsuleId = await capsuleService.saveCapsuleData(
        userId: userId,
        title: _titleController.text,
        content: _textContentController.text,
        imageUrl: imageUrl,
        location: GeoPoint(
          _geolocationController.currentPosition.value!.latitude,
          _geolocationController.currentPosition.value!.longitude,
        ),
        canUnlockedAt: openDate!,
        sharedWith: sharedWith,
      );

      widget.onSubmit(Capsule(
        id: capsuleId,
        userId: userId,
        title: _titleController.text,
        content: _textContentController.text,
        imageUrl: imageUrl,
        location: GeoPoint(
          _geolocationController.currentPosition.value!.latitude,
          _geolocationController.currentPosition.value!.longitude,
        ),
        uploadedAt: DateTime.now(),
        canUnlockedAt: openDate!,
        sharedWith: sharedWith,
      ));
      SnackbarUtil.showSuccess('성공', '캡슐 저장이 완료되었습니다!');
    } catch (e) {
      SnackbarUtil.showError('실패', '캡슐 저장 중 문제가 발생했습니다: $e');
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TimeAppBar(
        title: '기억하기',
        backButton: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                  height: 200,
                  child: MapScreen(
                    capsules: widget.capsules,
                    isLoading: false,
                    updateCapsules: () {},
                    canTap: false,
                  )),
              const SizedBox(height: 16),
              _buildInputField(_titleController, '제목'),
              const SizedBox(height: 16),
              _buildInputField(_textContentController, '글로 기억하기'),
              const SizedBox(height: 16),

              // 날짜 선택 위젯
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      openDate != null
                          ? DateFormat('yyyy년 MM월 dd일 - HH시 mm분')
                              .format(openDate!)
                          : '돌아오는 날짜를 선택하세요.',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickDateTime,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 사진 추가 및 삭제
              if (image == null)
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo),
                  label: const Text('사진으로 기억하기'),
                )
              else
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    SizedBox(
                      height: 200,
                      width: 200,
                      child: Image.file(
                        File(image!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: _removeImage,
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              _buildFriendsDropdown(), // 친구 선택 드롭다운
              const SizedBox(height: 8),
              _buildSelectedFriends(), // 선택된 친구 리스트
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () => _handleSubmit(userId),
                child: const Text('추가'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
