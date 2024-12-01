import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:timea/common/widgets/app_bar.dart';
import 'package:timea/common/widgets/snack_bar_util.dart';
import 'package:timea/core/controllers/geolocation_controller.dart';
import 'package:timea/core/services/firebase_auth_service.dart';
import 'package:timea/core/services/firestore_service.dart';
import 'package:timea/features/map/presentation/map_screen.dart';

class EnvelopeFormScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  final List<Map<String, dynamic>> capsules;

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
      Get.put(GeolocationController());
  DateTime? openDate;

  // 날짜 및 시간 선택
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

  // 이미지 선택
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

  Future<String?> _uploadImage() async {
    if (image == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('capsules/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = await storageRef.putFile(File(image!.path));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      SnackbarUtil.showError('이미지 업로드 실패', '이미지를 업로드하는 중 문제가 발생했습니다: $e');
      return null;
    }
  }

  String _calculateDday(DateTime targetDate) {
    final now = DateTime.now();
    final difference = targetDate.difference(now).inDays;

    if (difference > 0) {
      return 'D-$difference';
    } else if (difference == 0) {
      return 'D-Day';
    } else {
      return 'D+${-difference}'; // 개봉 날짜가 지났을 경우
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseAuthService authService = FirebaseAuthService();
    return Scaffold(
      appBar: const TimeAppBar(
        title: '기억하기 🔮',
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
                  showAppBar: false,
                  isLoading: false,
                  capsules: widget.capsules,
                ),
              ),
              const SizedBox(height: 16),
              Material(
                elevation: 1,
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Material(
                elevation: 1,
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                child: TextField(
                  controller: _textContentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '글로 기억하기',
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo),
                label: const Text('사진으로 기억하기'),
              ),
              if (image != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    height: 200,
                    width: 200,
                    child: Image.file(
                      File(image!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      openDate != null
                          ? DateFormat('yyyy년 MM월 dd일 - HH시 mm분')
                              .format(openDate!)
                          : '개봉 날짜를 선택하세요.',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (openDate != null)
                    Text(
                      _calculateDday(openDate!), // D-day 계산
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickDateTime,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: Text(
                        _geolocationController.currentPosition.value != null
                            ? '${_geolocationController.currentPosition.value!.latitude}, ${_geolocationController.currentPosition.value!.longitude}'
                            : '현재 위치를 가져오세요.',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.location_on),
                      onPressed: _geolocationController.getLocation,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_titleController.text.isNotEmpty &&
                      (_textContentController.text.isNotEmpty ||
                          image != null) &&
                      openDate != null &&
                      _geolocationController.currentPosition.value != null) {
                    final String? userId = authService.auth.currentUser?.uid;

                    if (userId == null) {
                      SnackbarUtil.showError(
                        '사용자 정보 없음',
                        '로그인된 사용자가 없습니다. 로그인 후 다시 시도해주세요.',
                      );
                      return;
                    }

                    final imageUrl = await _uploadImage();
                    final capsuleData = {
                      'title': _titleController.text,
                      'content': _textContentController.text,
                      'image': imageUrl ?? '',
                      'location': GeoPoint(
                        _geolocationController.currentPosition.value!.latitude,
                        _geolocationController.currentPosition.value!.longitude,
                      ),
                      'userId': userId,
                      'canUnlockedAt': openDate!,
                    };

                    final savedCapsuleId = await FirestoreService.saveCapsule(
                      title: _titleController.text,
                      content: _textContentController.text,
                      imageUrl: imageUrl ?? '',
                      location: GeoPoint(
                        _geolocationController.currentPosition.value!.latitude,
                        _geolocationController.currentPosition.value!.longitude,
                      ),
                      userId: userId,
                      canUnlockedAt: openDate!,
                    );

                    capsuleData['id'] = savedCapsuleId;

                    widget.onSubmit(capsuleData);
                    Get.offNamed('/home');
                  } else {
                    SnackbarUtil.showInfo(
                      '내용 입력 필요',
                      '필수 항목을 모두 입력해주세요.',
                    );
                  }
                },
                child: const Text('추가'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
