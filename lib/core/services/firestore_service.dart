import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> saveCapsule({
    required String title,
    required String content,
    required String imageUrl,
    required GeoPoint location,
    required String userId,
    required DateTime canUnlockedAt,
  }) async {
    final capsulesRef = _firestore.collection('capsules');

    try {
      await capsulesRef.add({
        'title': title,
        'content': content,
        'image': imageUrl,
        'location': location,
        'sharedWith': [], // 빈 배열
        'canUnlockedAt': Timestamp.fromDate(canUnlockedAt),
        'uploadedAt': Timestamp.now(), // 현재 시간
        'unlockedAt': null, // null
        'userId': userId,
      });
    } catch (e) {
      throw Exception('캡슐 저장 실패: $e');
    }
  }

  // Firestore에서 사용자 정보 가져오기
  static Future<DocumentSnapshot?> getUserProfile() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      return userDoc.exists ? userDoc : null;
    } catch (e) {
      throw Exception('프로필 데이터 로드 실패: $e');
    }
  }

  // Firestore에 사용자 정보 저장
  static Future<void> saveUserProfile({
    required User user,
    required String nickname,
    required String profileImage,
  }) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'nickname': nickname,
        'profileImage': profileImage,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'deletedAt': null,
      });
    } catch (e) {
      throw Exception('프로필 저장 실패: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllCapsules() async {
    try {
      final querySnapshot = await _firestore
          .collection('capsules')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('캡슐 목록을 가져오는 데 실패했습니다: $e');
    }
  }
}
