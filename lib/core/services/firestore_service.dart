import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // 닉네임으로 사용자 찾기 (닉네임은 unique)
  static Future<DocumentSnapshot?> findUserByNickname(String nickname) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('nickname', isEqualTo: nickname)
          .get();

      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first : null;
    } catch (e) {
      throw Exception('사용자를 찾을 수 없습니다');
    }
  }

  // 친구 요청 보내기
  static Future<void> sendFriendRequest(String targetUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final currentUserId = currentUser.uid;

    if (currentUserId == targetUserId) {
      throw Exception('자기 자신에게 친구 요청을 보낼 수 없습니다.');
    }

    final friendshipsRef = _firestore.collection('friendships');

    // 이미 친구인지 확인 (양방향 확인)
    final existingFriendship = await friendshipsRef
        .where('status', isEqualTo: 'accepted')
        .where(
          Filter.or(
            Filter.and(Filter('userId1', isEqualTo: currentUserId),
                Filter('userId2', isEqualTo: targetUserId)),
            Filter.and(Filter('userId1', isEqualTo: targetUserId),
                Filter('userId2', isEqualTo: currentUserId)),
          ),
        )
        .get();

    if (existingFriendship.docs.isNotEmpty) {
      throw Exception('이미 친구입니다.');
    }

    // 상대방이 나에게 친구 요청을 보냈는지 확인
    final incomingRequest = await friendshipsRef
        .where('userId1', isEqualTo: targetUserId)
        .where('userId2', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (incomingRequest.docs.isNotEmpty) {
      // 상대방이 보낸 요청을 수락
      await acceptFriendRequest(incomingRequest.docs.first.id);
      return;
    }

    // 내가 상대방에게 보낸 요청이 이미 있는지 확인
    final outgoingRequest = await friendshipsRef
        .where('userId1', isEqualTo: currentUserId)
        .where('userId2', isEqualTo: targetUserId)
        .where('status', whereIn: ['pending', 'accepted']).get();

    if (outgoingRequest.docs.isNotEmpty) {
      throw Exception('이미 친구 요청을 보냈거나 수락된 상태입니다.');
    }

    // 새로운 친구 요청 생성
    await friendshipsRef.add({
      'userId1': currentUserId,
      'userId2': targetUserId,
      'status': 'pending',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  // 친구 요청 수락
  static Future<void> acceptFriendRequest(String requestId) async {
    final friendshipRef = _firestore.collection('friendships').doc(requestId);

    try {
      await friendshipRef.update({
        'status': 'accepted',
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('친구 요청 수락 실패: $e');
    }
  }

  // 친구 요청 거절
  static Future<void> rejectFriendRequest(String requestId) async {
    final friendshipRef = _firestore.collection('friendships').doc(requestId);

    try {
      await friendshipRef.update({
        'status': 'rejected',
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('친구 요청 거절 실패: $e');
    }
  }

  // 친구 요청 취소
  static Future<void> cancelFriendRequest(String requestId) async {
    final friendshipRef = _firestore.collection('friendships').doc(requestId);

    try {
      await friendshipRef.update({
        'status': 'canceled',
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('친구 요청 취소 실패: $e');
    }
  }

  // 내가 보낸 친구 요청 목록 가져오기
  static Future<List<Map<String, dynamic>>> getFriendRequests() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    try {
      // 친구 요청 가져오기
      final querySnapshot = await _firestore
          .collection('friendships')
          .where('userId1', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (querySnapshot.docs.isEmpty) return [];

      // 상대방 ID 리스트 추출
      final targetUserIds =
          querySnapshot.docs.map((doc) => doc['userId2']).toList();

      // 상대방의 프로필 정보 가져오기
      final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: targetUserIds)
          .get();

      // 결과 결합: 요청 정보 + 상대방 프로필
      return querySnapshot.docs.map((doc) {
        final userData = usersSnapshot.docs.firstWhere(
          (userDoc) => userDoc.id == doc['userId2'],
        );
        return {
          'id': doc.id, // 친구 요청 문서 ID
          'userId': userData.id,
          'nickname': userData['nickname'],
          'profileImage': userData['profileImage'],
          'status': doc['status'],
        };
      }).toList();
    } catch (e) {
      throw Exception('보낸 친구 요청 목록을 가져오는 데 실패했습니다: $e');
    }
  }

  // 내가 받은 친구 요청 목록 가져오기
  static Future<List<Map<String, dynamic>>> getIncomingFriendRequests() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    try {
      // 받은 친구 요청 가져오기
      final querySnapshot = await _firestore
          .collection('friendships')
          .where('userId2', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (querySnapshot.docs.isEmpty) return [];

      // 요청한 상대방 ID 리스트 추출
      final requesterIds =
          querySnapshot.docs.map((doc) => doc['userId1']).toList();

      // 요청한 상대방의 프로필 정보 가져오기
      final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: requesterIds)
          .get();

      // 결과 결합: 요청 정보 + 상대방 프로필
      return querySnapshot.docs.map((doc) {
        final userData = usersSnapshot.docs.firstWhere(
          (userDoc) => userDoc.id == doc['userId1'],
        );
        return {
          'id': doc.id, // 친구 요청 문서 ID
          'userId': userData.id,
          'nickname': userData['nickname'],
          'profileImage': userData['profileImage'],
          'status': doc['status'],
        };
      }).toList();
    } catch (e) {
      throw Exception('받은 친구 요청 목록을 가져오는 데 실패했습니다: $e');
    }
  }

  static Future<int> getIncomingFriendRequestCount() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    try {
      final querySnapshot = await _firestore
          .collection('friendships')
          .where('userId2', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('받은 친구 요청 수를 가져오는 데 실패했습니다: $e');
    }
  }

  // 친구 목록 가져오기
  static Future<List<Map<String, dynamic>>> getFriends() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    try {
      final friendshipsQuery = await _firestore
          .collection('friendships')
          .where('status', isEqualTo: 'accepted')
          .where(
            Filter.or(
              Filter('userId1', isEqualTo: currentUserId),
              Filter('userId2', isEqualTo: currentUserId),
            ),
          )
          .get();

      final friendIds = friendshipsQuery.docs.map((doc) {
        final data = doc.data();
        return data['userId1'] == currentUserId
            ? data['userId2']
            : data['userId1'];
      }).toList();

      if (friendIds.isEmpty) return [];

      // 친구 프로필 정보 가져오기
      final friendsData = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: friendIds)
          .get();

      return friendsData.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // 문서 ID 추가
        return data;
      }).toList();
    } catch (e) {
      throw Exception('친구 목록을 가져오는 데 실패했습니다: $e');
    }
  }

  // 친구 수 가져오기
  static Future<int> getFriendCount() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    try {
      final friendshipsQuery = await _firestore
          .collection('friendships')
          .where('status', isEqualTo: 'accepted')
          .where(
            Filter.or(
              Filter('userId1', isEqualTo: currentUserId),
              Filter('userId2', isEqualTo: currentUserId),
            ),
          )
          .get();

      return friendshipsQuery.docs.length;
    } catch (e) {
      throw Exception('친구 수를 가져오는 데 실패했습니다: $e');
    }
  }

  // 친구 삭제
  static Future<void> deleteFriend(String targetUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    try {
      final friendshipQuery = await _firestore
          .collection('friendships')
          .where(
            Filter.or(
              Filter.and(Filter('userId1', isEqualTo: currentUserId),
                  Filter('userId2', isEqualTo: targetUserId)),
              Filter.and(Filter('userId1', isEqualTo: targetUserId),
                  Filter('userId2', isEqualTo: currentUserId)),
            ),
          )
          .get();

      for (var doc in friendshipQuery.docs) {
        await _firestore.collection('friendships').doc(doc.id).delete();
      }
    } catch (e) {
      throw Exception('친구 삭제 실패: $e');
    }
  }

  // 친구 관계 상태 확인
  static Future<String?> getFriendshipStatus(String targetUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    try {
      final friendshipQuery = await _firestore
          .collection('friendships')
          .where(
            Filter.or(
              Filter.and(Filter('userId1', isEqualTo: currentUserId),
                  Filter('userId2', isEqualTo: targetUserId)),
              Filter.and(Filter('userId1', isEqualTo: targetUserId),
                  Filter('userId2', isEqualTo: currentUserId)),
            ),
          )
          .get();

      if (friendshipQuery.docs.isEmpty) return null;

      final status = friendshipQuery.docs.first.data()['status'];
      return status; // pending, accepted, rejected, canceled
    } catch (e) {
      throw Exception('친구 관계 상태를 확인할 수 없습니다: $e');
    }
  }

  static Future<String> saveCapsule({
    required String title,
    required String content,
    required String imageUrl,
    required GeoPoint location,
    required String userId,
    required DateTime canUnlockedAt,
    List<String> sharedWith = const [],
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
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    try {
      final querySnapshot = await _firestore
          .collection('capsules')
          .where(
            Filter.or(
              Filter('userId', isEqualTo: currentUserId),
              Filter('sharedWith', arrayContains: currentUserId),
            ),
          )
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // 문서 ID 추가
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
