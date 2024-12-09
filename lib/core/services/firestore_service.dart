import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timea/core/model/capsule.dart';
import 'package:timea/core/model/user.dart';
import 'package:timea/core/utils/api_client.dart';
import 'package:timea/core/utils/format_util.dart';

class FirestoreService {
  static final _firestore = FirebaseFirestore.instance;
  static final apiClient = ApiClient();

  static Future<UserModel?> getUserProfile() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final response = await apiClient.get('/users/$userId');
    if (response == null) throw Exception('사용자 정보를 찾을 수 없습니다.');

    return UserModel.fromJson(userId.toString(), response);
  }

  // 닉네임 중복 확인
  static Future<bool> isNicknameExists(String nickname) async {
    try {
      // 필터링을 위한 Firestore REST API 쿼리 요청 구성
      const path = ':runQuery';
      final requestBody = {
        "structuredQuery": {
          "from": [
            {"collectionId": "users"}
          ],
          "where": {
            "fieldFilter": {
              "field": {"fieldPath": "nickname"},
              "op": "EQUAL",
              "value": {"stringValue": nickname}
            }
          },
          "limit": 1
        }
      };

      final response = await apiClient.post(path, requestBody);

      if (response != null && response is List) {
        // 문서가 없을 때는 readTime만 포함된 요소가 반환됨
        bool documentExists =
            response.any((doc) => doc.containsKey('document'));
        return documentExists;
      }

      return false; // 응답이 비어있으면 중복 아님
    } catch (e) {
      throw Exception('닉네임 중복 확인 실패: $e');
    }
  }

  static Future<void> updateUserProfile({
    required String userId,
    String? nickname,
    String? profileImage,
  }) async {
    try {
      final path = '/users/$userId';
      final fieldsToUpdate = <String, dynamic>{};
      final updateMask = <String>[];

      // 업데이트할 필드 추가
      if (nickname != null && nickname.isNotEmpty) {
        fieldsToUpdate['nickname'] = {"stringValue": nickname};
        updateMask.add('nickname');
      }

      if (profileImage != null && profileImage.isNotEmpty) {
        fieldsToUpdate['profileImage'] = {"stringValue": profileImage};
        updateMask.add('profileImage');
      }

      fieldsToUpdate['updatedAt'] = {
        "timestampValue": DateTime.now().toUtc().toIso8601String(),
      };
      updateMask.add('updatedAt');

      // 쿼리 파라미터에 updateMask 추가
      final queryParameters = {'updateMask.fieldPaths': updateMask};

      // 요청 Body
      final body = {"fields": fieldsToUpdate};

      await apiClient.update(path, body, queryParameters: queryParameters);
    } catch (e) {
      throw Exception('프로필 업데이트 실패: $e');
    }
  }

  // 닉네임으로 사용자 찾기 (닉네임은 unique)
  static Future<UserModel> findUserByNickname(String nickname) async {
    const path = ':runQuery';
    final requestBody = {
      "structuredQuery": {
        "from": [
          {"collectionId": "users"}
        ],
        "where": {
          "fieldFilter": {
            "field": {"fieldPath": "nickname"},
            "op": "EQUAL",
            "value": {"stringValue": nickname}
          }
        },
        "limit": 1
      }
    };

    try {
      final response = await apiClient.post(path, requestBody);

      if (response is List && response.isNotEmpty) {
        final document = response.first['document'];
        final String userId = document['name'].split('/').last;
        final Map<String, dynamic> fields = document;

        return UserModel.fromJson(userId, fields);
      } else {
        throw Exception('사용자를 찾을 수 없습니다.');
      }
    } catch (e) {
      throw Exception('사용자를 찾을 수 없습니다.');
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

  static Future<List<Capsule>> getAllCapsules() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final query = {
      "structuredQuery": {
        "from": [
          {"collectionId": "capsules"}
        ],
        "where": {
          "compositeFilter": {
            "op": "OR",
            "filters": [
              {
                "fieldFilter": {
                  "field": {"fieldPath": "userId"},
                  "op": "EQUAL",
                  "value": {"stringValue": currentUserId}
                }
              },
              {
                "fieldFilter": {
                  "field": {"fieldPath": "sharedWith"},
                  "op": "ARRAY_CONTAINS",
                  "value": {"stringValue": currentUserId}
                }
              }
            ]
          }
        }
      }
    };

    try {
      // Firestore REST API 요청
      final response = await apiClient.post(
        ':runQuery', // Firestore REST API의 쿼리 실행 경로
        query,
      );

      // 결과 파싱
      final capsules = (response as List)
          .where((doc) => doc['document'] != null) // document가 null인 경우 제외
          .map((doc) {
        final data = doc['document']['fields'];
        final id = doc['document']['name'].split('/').last;
        return Capsule.fromJson(id, {"fields": data});
      }).toList();
      return capsules;
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
  static Future<Capsule> updateCapsuleStatus({
    required String capsuleId, // 캡슐 ID
    required DateTime unlockedAt, // 캡슐 해제 시간
  }) async {
    final path = '/capsules/$capsuleId';
    final fieldsToUpdate = <String, dynamic>{
      'unlockedAt': {'timestampValue': FormatUtil.formatTimestamp(unlockedAt)},
      'updatedAt': {
        'timestampValue': FormatUtil.formatTimestamp(DateTime.now())
      },
    };
    final body = {'fields': fieldsToUpdate};
    final queryParmeters = {
      'updateMask.fieldPaths': ['unlockedAt', 'updatedAt']
    };

    try {
      final response =
          await apiClient.update(path, body, queryParameters: queryParmeters);

      final Capsule capsule = Capsule.fromJson(capsuleId, response);
      return capsule;
    } catch (e) {
      throw Exception('캡슐 상태 업데이트 실패: $e');
    }
  }
}
