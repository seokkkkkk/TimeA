import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<String> saveCapsule({
    required String title,
    required String content,
    required String imageUrl,
    required GeoPoint location,
    required String userId,
    required DateTime canUnlockedAt,
  }) async {
    final capsulesRef = _firestore.collection('capsules');

    try {
      return await capsulesRef.add({
        'title': title,
        'content': content,
        'image': imageUrl,
        'location': location,
        'sharedWith': [], // 빈 배열
        'canUnlockedAt': Timestamp.fromDate(canUnlockedAt),
        'uploadedAt': Timestamp.now(), // 현재 시간
        'unlockedAt': null, // null
        'userId': userId,
      }).then((doc) => doc.id);
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
  static Future<void> updateUserProfile({
    required User user,
    required String nickname,
    required String profileImage,
  }) async {
    try {
      (profileImage.isNotEmpty)
          ? await _firestore.collection('users').doc(user.uid).set({
              'nickname': nickname,
              'profileImage': profileImage,
              'updatedAt': Timestamp.now(),
            })
          : await _firestore.collection('users').doc(user.uid).set({
              'nickname': nickname,
              'updatedAt': Timestamp.now(),
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

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // 문서 ID를 추가
        return data;
      }).toList();
    } catch (e) {
      throw Exception('캡슐 목록을 가져오는 데 실패했습니다: $e');
    }
  }

  /// 캡슐 상태 업데이트
  static Future<void> updateCapsuleStatus({
    required String capsuleId, // 캡슐 ID
    required DateTime unlockedAt, // 캡슐 해제 시간
  }) async {
    final capsuleRef = _firestore.collection('capsules').doc(capsuleId);

    try {
      await capsuleRef.update({
        'unlockedAt': Timestamp.fromDate(unlockedAt),
      });
    } catch (e) {
      throw Exception('캡슐 상태 업데이트 실패: $e');
    }
  }
}
