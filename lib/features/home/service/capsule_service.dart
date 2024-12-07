import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:timea/common/widgets/snack_bar_util.dart';

class CapsuleService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    required String userId,
    required String title,
    required String content,
    required String imageUrl,
    required GeoPoint location,
    required DateTime canUnlockedAt,
    List sharedWith = const [],
  }) async {
    try {
      // 데이터를 Firestore에 추가하고 문서 참조를 반환받습니다.
      final docRef = await _firestore.collection('capsules').add({
        'title': title,
        'content': content.isEmpty ? null : content,
        'imageUrl': imageUrl.isEmpty ? null : imageUrl,
        'location': location,
        'userId': userId,
        'canUnlockedAt': Timestamp.fromDate(canUnlockedAt),
        'uploadedAt': Timestamp.now(),
        'unlockedAt': null, // 처음엔 null
        'sharedWith': sharedWith,
      });

      // 자동 생성된 문서 ID 반환
      return docRef.id;
    } catch (e) {
      SnackbarUtil.showError('캡슐 저장 실패', '캡슐 데이터를 저장하는 중 문제가 발생했습니다: $e');
      rethrow;
    }
  }
}
