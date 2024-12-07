import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timea/common/widgets/snack_bar_util.dart';

class CapsuleService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> uploadImage(String userId, XFile image) async {
    try {
      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final storageRef =
          _storage.ref().child('capsules/$userId/$uniqueFileName');
      final uploadTask = await storageRef.putFile(File(image.path));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      SnackbarUtil.showError('이미지 업로드 실패', '이미지를 업로드하는 중 문제가 발생했습니다: $e');
      return null;
    }
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
