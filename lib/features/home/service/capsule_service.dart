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
      final storageRef = _storage.ref().child('capsules/$userId/');
      final uploadTask = await storageRef.putFile(File(image.path));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      SnackbarUtil.showError('이미지 업로드 실패', '이미지를 업로드하는 중 문제가 발생했습니다: $e');
      return null;
    }
  }

  Future<void> saveCapsuleData({
    required String capsuleId,
    required String userId,
    required String title,
    required String content,
    required String imageUrl,
    required GeoPoint location,
    required DateTime canUnlockedAt,
  }) async {
    try {
      await _firestore.collection('capsules').doc(capsuleId).set({
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'location': location,
        'userId': userId,
        'canUnlockedAt': Timestamp.fromDate(canUnlockedAt),
      });
    } catch (e) {
      SnackbarUtil.showError('캡슐 저장 실패', '캡슐 데이터를 저장하는 중 문제가 발생했습니다: $e');
      rethrow;
    }
  }
}
