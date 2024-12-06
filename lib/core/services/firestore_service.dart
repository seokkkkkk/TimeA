import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timea/common/widgets/snack_bar_util.dart';

class FirestoreService {
  static final _firestore = FirebaseFirestore.instance;

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

  // 닉네임 중복 확인
  static Future<bool> isNicknameExists(String nickname) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('nickname', isEqualTo: nickname)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('닉네임 중복 확인 실패: $e');
    }
  }

  // Firestore에 사용자 정보 저장
  static Future<void> updateUserProfile({
    required User user,
    required String nickname,
    required String profileImage,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (profileImage.isNotEmpty) {
        data['profileImage'] = profileImage;
      }
      if (nickname.isNotEmpty) {
        data['nickname'] = nickname;
      }
      data['updatedAt'] = Timestamp.now();

      await _firestore.collection('users').doc(user.uid).update(data);
    } catch (e) {
      throw Exception('프로필 저장 실패: $e');
    }
  }

  // 친구 요청 보내기
  static Future<void> sendFriendRequest(String nickname) async {
    final user = FirebaseAuth.instance.currentUser!;
    final userQuery = await _firestore
        .collection('users')
        .where('nickname', isEqualTo: nickname)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception('사용자를 찾을 수 없습니다.');
    }

    final targetUserId = userQuery.docs.first.id;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final friends = List<String>.from(userDoc.data()?['friends'] ?? []);
    if (friends.contains(targetUserId)) {
      throw Exception('이미 친구입니다.');
    }

    final requests = await Future.wait([
      _firestore
          .collection('friendRequests')
          .where('from', isEqualTo: user.uid)
          .where('to', isEqualTo: targetUserId)
          .where('status', isEqualTo: 'pending')
          .get(),
      _firestore
          .collection('friendRequests')
          .where('from', isEqualTo: targetUserId)
          .where('to', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get()
    ]);

    if (requests[0].docs.isNotEmpty) {
      throw Exception('이미 친구 요청을 보냈습니다.');
    }

    if (requests[1].docs.isNotEmpty) {
      acceptFriendRequest(requests[1].docs.first.id);
      SnackbarUtil.showSuccess('친구 추가 성공', '상대방이 보낸 친구 요청을 수락했습니다.');
      return; // 중복 요청 방지
    }

    try {
      await _firestore.collection('friendRequests').add({
        'from': user.uid,
        'to': targetUserId,
        'status': 'pending',
        'requestedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('친구 요청 보내기 실패: $e');
    }
  }

  // 친구 요청 수락
  static Future<void> acceptFriendRequest(String requestId) async {
    final requestRef = _firestore.collection('friendRequests').doc(requestId);

    try {
      // 친구 요청 상태 업데이트
      await requestRef.update({
        'status': 'accepted',
        'acceptedAt': Timestamp.now(),
      });

      // 요청 데이터 가져오기
      final requestSnapshot = await requestRef.get();
      final requestData = requestSnapshot.data();

      if (requestData == null) {
        throw Exception('유효하지 않은 친구 요청입니다.');
      }

      final fromUserId = requestData['from'];
      final toUserId = requestData['to'];

      // 친구 관계 업데이트 함수
      Future<void> updateFriends(String userId, String friendId) async {
        final userRef = _firestore.collection('users').doc(userId);

        await _firestore.runTransaction((transaction) async {
          final userSnapshot = await transaction.get(userRef);

          if (userSnapshot.exists) {
            final friends =
                List<String>.from(userSnapshot.data()?['friends'] ?? []);
            if (!friends.contains(friendId)) {
              friends.add(friendId);
              transaction.update(userRef, {'friends': friends});
            }
          } else {
            throw Exception('사용자 정보를 찾을 수 없습니다: $userId');
          }
        });
      }

      // 두 사용자 간의 친구 관계 업데이트
      await Future.wait([
        updateFriends(fromUserId, toUserId),
        updateFriends(toUserId, fromUserId),
      ]);
    } catch (e) {
      throw Exception('친구 요청 수락 실패: $e');
    }
  }

  // 친구 요청 거절
  static Future<void> rejectFriendRequest(String requestId) async {
    final requestRef = _firestore.collection('friendRequests').doc(requestId);

    try {
      await requestRef.update({
        'status': 'rejected',
        'rejectedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('친구 요청 거절 실패: $e');
    }
  }

  // 친구 요청 목록 가져오기
  static Future<List<Map<String, dynamic>>> getFriendRequests() async {
    final user = FirebaseAuth.instance.currentUser!;

    try {
      final querySnapshot = await _firestore
          .collection('friendRequests')
          .where('to', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // 문서 ID를 추가
        return data;
      }).toList();
    } catch (e) {
      throw Exception('친구 요청 목록 가져오기 실패: $e');
    }
  }

  // 친구 삭제
  static Future<void> deleteFriend(String friendId) async {
    final user = FirebaseAuth.instance.currentUser!;

    try {
      // 친구 삭제 로직 함수
      Future<void> updateFriends(String userId, String friendId) async {
        final userRef = _firestore.collection('users').doc(userId);

        await _firestore.runTransaction((transaction) async {
          final userSnapshot = await transaction.get(userRef);
          if (userSnapshot.exists) {
            final friends =
                List<String>.from(userSnapshot.data()?['friends'] ?? []);
            if (friends.contains(friendId)) {
              friends.remove(friendId);
              transaction.update(userRef, {'friends': friends});
            } else {
              throw Exception('친구 관계를 찾을 수 없습니다: $userId -> $friendId');
            }
          } else {
            throw Exception('사용자 정보를 찾을 수 없습니다: $userId');
          }
        });
      }

      // 두 사용자 간 친구 관계 삭제
      await Future.wait([
        updateFriends(user.uid, friendId),
        updateFriends(friendId, user.uid),
      ]);
    } catch (e) {
      throw Exception('친구 삭제 실패: $e');
    }
  }

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
        'uploadedAt': Timestamp.now(),
        'unlockedAt': null, // null
        'userId': userId,
      }).then((doc) => doc.id);
    } catch (e) {
      throw Exception('캡슐 저장 실패: $e');
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

  static Future<Map<String, dynamic>> getCapsule(String capsuleId) async {
    try {
      final querySnapshot =
          await _firestore.collection('capsules').doc(capsuleId).get();

      final capsule = querySnapshot.data();
      capsule!['id'] = querySnapshot.id; // 문서 ID를 추가
      return capsule;
    } catch (e) {
      throw Exception('캡슐을 가져오는 데 실패했습니다: $e');
    }
  }

  /// 캡슐 상태 업데이트
  static Future<Map<String, dynamic>> updateCapsuleStatus({
    required String capsuleId, // 캡슐 ID
    required DateTime unlockedAt, // 캡슐 해제 시간
  }) async {
    final capsuleRef = _firestore.collection('capsules').doc(capsuleId);

    try {
      await capsuleRef.update({
        'unlockedAt': Timestamp.fromDate(unlockedAt),
      });

      final newCapsule = capsuleRef.get().then(
        (doc) {
          final capsule = doc.data();
          capsule!['id'] = doc.id; // 문서 ID를 추가
          return capsule;
        },
      );

      return newCapsule;
    } catch (e) {
      throw Exception('캡슐 상태 업데이트 실패: $e');
    }
  }
}
