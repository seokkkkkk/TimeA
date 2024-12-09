import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:timea/common/widgets/snack_bar_util.dart';
import 'package:timea/core/model/capsule.dart';
import 'package:timea/core/utils/api_client.dart';

class CapsuleService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static final apiClient = ApiClient();

  Future<String?> uploadImage(String userId, XFile image,
      {int minHeight = 1920, int minWidth = 1080, int quality = 85}) async {
    try {
      final compressedImage = await compressImage(image,
          minHeight: minHeight, minWidth: minWidth, quality: quality);
      if (compressedImage == null) {
        throw Exception('이미지 압축 실패');
      }

      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_${compressedImage.name}';
      final storageRef =
          _storage.ref().child('capsules/$userId/$uniqueFileName');
      final uploadTask = await storageRef.putFile(File(compressedImage.path));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      SnackbarUtil.showError('이미지 업로드 실패', '이미지를 업로드하는 중 문제가 발생했습니다: $e');
      return null;
    }
  }

  Future<XFile?> compressImage(XFile file,
      {int minHeight = 1920, int minWidth = 1080, int quality = 85}) async {
    final targetPath = '${file.path}_compressed.jpg';

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.path, // 원본 파일 경로
        targetPath, // 압축된 파일 저장 경로
        quality: quality, // 압축 품질
        minHeight: minHeight,
        minWidth: minWidth);

    return compressedFile;
  }

  Future<String> saveCapsuleData({
    required String title,
    required String content,
    required String imageUrl,
    required GeoPoint location,
    required String userId,
    required DateTime canUnlockedAt,
    List<String> sharedWith = const [],
  }) async {
    const path = '/capsules';

    Capsule capsule = Capsule(
      id: '',
      title: title,
      content: content,
      imageUrl: imageUrl,
      sharedWith: sharedWith,
      canUnlockedAt: canUnlockedAt,
      unlockedAt: null,
      uploadedAt: DateTime.now(),
      userId: userId,
      location: location,
    );

    final body = {
      "fields": capsule.toJson(),
    };

    try {
      final response = await apiClient.post(path, body);
      return response['name'].split('/').last;
    } catch (e) {
      throw Exception('캡슐 저장 실패: $e');
    }
  }
}
