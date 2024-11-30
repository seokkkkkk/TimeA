import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:timea/common/widgets/snack_bar_util.dart';
import 'package:timea/core/controllers/geolocation_controller.dart';
import 'package:timea/features/map/presentation/map_screen.dart';

class EnvelopeForm extends StatefulWidget {
  final VoidCallback onSubmit;

  const EnvelopeForm({super.key, required this.onSubmit});

  @override
  State<EnvelopeForm> createState() => _EnvelopeFormState();
}

class _EnvelopeFormState extends State<EnvelopeForm> {
  final picker = ImagePicker();
  XFile? image;
  final _titleController = TextEditingController();
  final GeolocationController _geolocationController =
      Get.put(GeolocationController());
  DateTime? openDate;
  final Map<String, bool> selectedOptions = {
    '텍스트': false,
    '이미지': false,
    '녹음': false,
  };
  final Map<String, Widget> formWidgets = {};

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
  void _pickImage() async {
    try {
      final pickedImage = await picker.pickImage(source: ImageSource.camera);

      if (pickedImage != null) {
        setState(() {
          image = pickedImage;
          formWidgets['이미지'] = Column(
            children: [
              const Text('촬영된 이미지'),
              SizedBox(
                height: 200,
                width: 200,
                child: Image.file(
                  File(image!.path),
                  fit: BoxFit.cover,
                ),
              ),
            ],
          );
        });
      } else {
        SnackbarUtil.showInfo('이미지 선택', '이미지를 선택하지 않았습니다.');
      }
    } catch (e) {
      SnackbarUtil.showError('에러', '이미지를 불러오는 중 문제가 발생했습니다: $e');
    }
  }

  void _toggleOption(String option) {
    setState(() {
      if (selectedOptions[option] == true) {
        selectedOptions[option] = false;
      } else {
        selectedOptions[option] = true;
      }

      formWidgets.clear();
      if (selectedOptions['이미지'] == true) {
        _pickImage();
      }
      if (selectedOptions['텍스트'] == true) {
        formWidgets['텍스트'] = Material(
          elevation: 1,
          borderRadius: BorderRadius.circular(8),
          child: const TextField(
            decoration: InputDecoration(
              labelText: '텍스트 입력',
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
        );
      }
      if (selectedOptions['녹음'] == true) {
        formWidgets['녹음'] = const Text('녹음을 추가하세요.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 200,
              child: MapScreen(
                showAppBar: false,
              ),
            ),
            const SizedBox(height: 16),
            Material(
              elevation: 1,
              borderRadius: BorderRadius.circular(8),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: selectedOptions.keys.map((option) {
                return IconButton(
                  icon: Icon(
                    option == '텍스트'
                        ? Icons.text_fields
                        : option == '이미지'
                            ? Icons.image
                            : Icons.mic,
                  ),
                  onPressed: () => _toggleOption(option),
                  color: selectedOptions[option]! ? Colors.blue : Colors.black,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Column(
              children: formWidgets.values.toList(),
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
                          ? '현재 위치: ${_geolocationController.currentPosition.value!.latitude}, ${_geolocationController.currentPosition.value!.longitude}'
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
              onPressed: () {
                if (_titleController.text.isNotEmpty &&
                    selectedOptions.containsValue(true) &&
                    openDate != null &&
                    _geolocationController.currentPosition.value != null) {
                  widget.onSubmit();
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
    );
  }
}
