import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timea/core/model/capsule.dart';
import 'package:timea/core/model/user.dart';
import 'package:timea/core/utils/api_client.dart';
import 'package:timea/core/utils/format_util.dart';

class FirestoreService {
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
        "timestampValue": FormatUtil.formatTimestamp(DateTime.now())
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
    const checkPath = ':runQuery';
    const createPath = '/friendships';

    try {
      // 1. 중복 친구 요청 확인 쿼리
      final query = {
        "structuredQuery": {
          "from": [
            {"collectionId": "friendships"}
          ],
          "where": {
            "compositeFilter": {
              "op": "AND",
              "filters": [
                {
                  "compositeFilter": {
                    "op": "OR",
                    "filters": [
                      {
                        "compositeFilter": {
                          "op": "AND",
                          "filters": [
                            {
                              "fieldFilter": {
                                "field": {"fieldPath": "userId1"},
                                "op": "EQUAL",
                                "value": {"stringValue": currentUser.uid}
                              }
                            },
                            {
                              "fieldFilter": {
                                "field": {"fieldPath": "userId2"},
                                "op": "EQUAL",
                                "value": {"stringValue": targetUserId}
                              }
                            }
                          ]
                        }
                      },
                      {
                        "compositeFilter": {
                          "op": "AND",
                          "filters": [
                            {
                              "fieldFilter": {
                                "field": {"fieldPath": "userId1"},
                                "op": "EQUAL",
                                "value": {"stringValue": targetUserId}
                              }
                            },
                            {
                              "fieldFilter": {
                                "field": {"fieldPath": "userId2"},
                                "op": "EQUAL",
                                "value": {"stringValue": currentUser.uid}
                              }
                            }
                          ]
                        }
                      }
                    ]
                  }
                },
                {
                  "fieldFilter": {
                    "field": {"fieldPath": "status"},
                    "op": "IN",
                    "value": {
                      "arrayValue": {
                        "values": [
                          {"stringValue": "pending"},
                          {"stringValue": "accepted"}
                        ]
                      }
                    }
                  }
                }
              ]
            }
          }
        }
      };

      // 2. 중복 친구 요청 확인
      final response = await apiClient.post(checkPath, query);

      // 'readTime' 제거 및 'document'가 있는 항목만 확인
      final validDocuments =
          (response as List).where((doc) => doc['document'] != null).toList();

      if (validDocuments.isEmpty) {
        // 3. 친구 요청 생성
        final body = {
          'fields': {
            'userId1': {'stringValue': currentUser.uid},
            'userId2': {'stringValue': targetUserId},
            'status': {'stringValue': 'pending'},
            'createdAt': {
              'timestampValue': FormatUtil.formatTimestamp(DateTime.now())
            },
            'updatedAt': {
              'timestampValue': FormatUtil.formatTimestamp(DateTime.now())
            },
          }
        };

        await apiClient.post(createPath, body);
      } else {
        throw Exception('이미 친구 요청을 보냈거나 친구 관계가 있습니다.');
      }
    } catch (e) {
      throw Exception('친구 요청 보내기 실패: $e');
    }
  }

  // 친구 요청 수락
  static Future<void> acceptFriendRequest(String requestId) async {
    final path = '/friendships/$requestId';

    final body = {
      'fields': {
        'status': {'stringValue': 'accepted'},
        'updatedAt': {
          'timestampValue': FormatUtil.formatTimestamp(DateTime.now())
        },
      }
    };

    final queryParameters = {
      'updateMask.fieldPaths': ['status', 'updatedAt']
    };

    try {
      await apiClient.update(path, body, queryParameters: queryParameters);
    } catch (e) {
      throw Exception('친구 요청 수락 실패: $e');
    }
  }

  // 친구 요청 거절
  static Future<void> rejectFriendRequest(String requestId) async {
    final path = '/friendships/$requestId';

    final body = {
      'fields': {
        'status': {'stringValue': 'rejected'},
        'updatedAt': {
          'timestampValue': FormatUtil.formatTimestamp(DateTime.now())
        },
      }
    };

    final queryParameters = {
      'updateMask.fieldPaths': ['status', 'updatedAt']
    };

    try {
      await apiClient.update(path, body, queryParameters: queryParameters);
    } catch (e) {
      throw Exception('친구 요청 거절 실패: $e');
    }
  }

  // 친구 요청 취소
  static Future<void> cancelFriendRequest(String requestId) async {
    final path = '/friendships/$requestId';

    final body = {
      'fields': {
        'status': {'stringValue': 'cancelled'},
        'updatedAt': {
          'timestampValue': FormatUtil.formatTimestamp(DateTime.now())
        },
      }
    };

    final queryParameters = {
      'updateMask.fieldPaths': ['status', 'updatedAt']
    };

    try {
      await apiClient.update(path, body, queryParameters: queryParameters);
    } catch (e) {
      throw Exception('친구 요청 취소 실패: $e');
    }
  }

  // 내가 보낸 친구 요청 목록 가져오기
  static Future<List<Map<String, dynamic>>> getFriendRequests() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    const path = ':runQuery';

    final query = {
      'structuredQuery': {
        'from': [
          {'collectionId': 'friendships'}
        ],
        "where": {
          "compositeFilter": {
            "op": "AND",
            "filters": [
              {
                "fieldFilter": {
                  "field": {"fieldPath": "userId1"},
                  "op": "EQUAL",
                  "value": {"stringValue": currentUserId}
                }
              },
              {
                "fieldFilter": {
                  "field": {"fieldPath": "status"},
                  "op": "EQUAL",
                  "value": {"stringValue": "pending"}
                }
              }
            ]
          }
        }
      }
    };

    try {
      final response = await apiClient.post(path, query);

      if (response is List) {
        // 문서가 있는 항목만 필터링 (readTime 제외)
        final documents =
            response.where((doc) => doc['document'] != null).toList();

        // 상대방 ID 리스트 추출
        final targetUserIds = documents.map((doc) {
          final data = doc['document']['fields'];
          return data['userId2']['stringValue'];
        }).toList();

        if (targetUserIds.isEmpty) return [];

        // 상대방의 프로필 정보 가져오기
        final users = await getUsersByIds(targetUserIds);

        //users에 id로 request의 id를 추가
        for (int i = 0; i < users.length; i++) {
          users[i]['id'] = documents[i]['document']['name'].split('/').last;
        }
        return users;
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('보낸 친구 요청 목록을 가져오는 데 실패했습니다: $e');
    }
  }

  // 내가 받은 친구 요청 목록 가져오기
  static Future<List<Map<String, dynamic>>> getIncomingFriendRequests() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    const path = ':runQuery';

    final query = {
      'structuredQuery': {
        'from': [
          {'collectionId': 'friendships'}
        ],
        "where": {
          "compositeFilter": {
            "op": "AND",
            "filters": [
              {
                "fieldFilter": {
                  "field": {"fieldPath": "userId2"},
                  "op": "EQUAL",
                  "value": {"stringValue": currentUserId}
                }
              },
              {
                "fieldFilter": {
                  "field": {"fieldPath": "status"},
                  "op": "EQUAL",
                  "value": {"stringValue": "pending"}
                }
              }
            ]
          }
        }
      }
    };

    try {
      final response = await apiClient.post(path, query);

      if (response is List) {
        // 문서가 있는 항목만 필터링 (readTime 제외)
        final documents =
            response.where((doc) => doc['document'] != null).toList();

        // 상대방 ID 리스트 추출
        final targetUserIds = documents.map((doc) {
          final data = doc['document']['fields'];
          return data['userId1']['stringValue'];
        }).toList();

        if (targetUserIds.isEmpty) return [];

        // 상대방의 프로필 정보 가져오기
        final users = await getUsersByIds(targetUserIds);

        //users에 id로 request의 id를 추가
        for (int i = 0; i < users.length; i++) {
          users[i]['id'] = documents[i]['document']['name'].split('/').last;
        }
        return users;
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('받은 친구 요청 목록을 가져오는 데 실패했습니다: $e');
    }
  }

  // 받은 친구 요청 수 가져오기
  static Future<int> getIncomingFriendRequestCount() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    const path = ':runQuery';

    final query = {
      'structuredQuery': {
        'from': [
          {'collectionId': 'friendships'}
        ],
        "where": {
          "compositeFilter": {
            "op": "AND",
            "filters": [
              {
                "fieldFilter": {
                  "field": {"fieldPath": "userId2"},
                  "op": "EQUAL",
                  "value": {"stringValue": currentUserId}
                }
              },
              {
                "fieldFilter": {
                  "field": {"fieldPath": "status"},
                  "op": "EQUAL",
                  "value": {"stringValue": "pending"}
                }
              }
            ]
          }
        }
      }
    };

    try {
      final response = await apiClient.post(path, query);

      final count = response.where((doc) => doc['document'] != null).length;
      return count;
    } catch (e) {
      throw Exception('받은 친구 요청 수를 가져오는 데 실패했습니다: $e');
    }
  }

  // 친구 목록 가져오기
  static Future<List<Map<String, dynamic>>> getFriends() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    const path = ':runQuery';

    final query = {
      "structuredQuery": {
        "from": [
          {"collectionId": "friendships"}
        ],
        "where": {
          "compositeFilter": {
            "op": "AND",
            "filters": [
              {
                "fieldFilter": {
                  "field": {"fieldPath": "status"},
                  "op": "EQUAL",
                  "value": {"stringValue": "accepted"}
                }
              },
              {
                "compositeFilter": {
                  "op": "OR",
                  "filters": [
                    {
                      "fieldFilter": {
                        "field": {"fieldPath": "userId1"},
                        "op": "EQUAL",
                        "value": {"stringValue": currentUserId}
                      }
                    },
                    {
                      "fieldFilter": {
                        "field": {"fieldPath": "userId2"},
                        "op": "EQUAL",
                        "value": {"stringValue": currentUserId}
                      }
                    }
                  ]
                }
              }
            ]
          }
        }
      }
    };

    try {
      // 친구 관계 조회
      final response = await apiClient.post(path, query);

      if (response is List) {
        // 문서가 있는 항목만 필터링 (readTime 제외)
        final documents =
            response.where((doc) => doc['document'] != null).toList();

        // 상대방 ID 리스트 추출
        final friendIds =
            documents.where((doc) => doc['document'] != null).map((doc) {
          final data = doc['document']['fields'];
          final userId1 = data['userId1']['stringValue'];
          final userId2 = data['userId2']['stringValue'];
          return userId1 == currentUserId ? userId2 : userId1;
        }).toList();

        if (friendIds.isEmpty) return [];

        // 상대방의 프로필 정보 가져오기
        final friends = await getUsersByIds(friendIds);
        return friends;
      } else {
        return [];
      }
    } catch (e) {
      print(e);
      throw Exception('친구 목록을 가져오는 데 실패했습니다: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getUsersByIds(
      List<dynamic> userIds) async {
    const path = ':batchGet';

    final body = {
      "documents": userIds.map((id) {
        return "projects/time-a-42e3d/databases/(default)/documents/users/$id";
      }).toList(),
    };

    try {
      final response = await apiClient.post(path, body);

      if (response is List) {
        return response.map((doc) {
          final data = doc['found'];
          final userId = doc['found']['name'].split('/').last;
          return {
            'userId': userId,
            'nickname': data['fields']['nickname']['stringValue'],
            'profileImage': data['fields']['profileImage']['stringValue'],
          };
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('사용자 정보를 가져오는 데 실패했습니다: $e');
    }
  }

  // 친구 수 가져오기
  static Future<int> getFriendCount() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    const path = ':runQuery';

    final query = {
      "structuredQuery": {
        "from": [
          {"collectionId": "friendships"}
        ],
        "where": {
          "compositeFilter": {
            "op": "AND",
            "filters": [
              {
                "fieldFilter": {
                  "field": {"fieldPath": "status"},
                  "op": "EQUAL",
                  "value": {"stringValue": "accepted"}
                }
              },
              {
                "compositeFilter": {
                  "op": "OR",
                  "filters": [
                    {
                      "fieldFilter": {
                        "field": {"fieldPath": "userId1"},
                        "op": "EQUAL",
                        "value": {"stringValue": currentUserId}
                      }
                    },
                    {
                      "fieldFilter": {
                        "field": {"fieldPath": "userId2"},
                        "op": "EQUAL",
                        "value": {"stringValue": currentUserId}
                      }
                    }
                  ]
                }
              }
            ]
          }
        }
      }
    };

    try {
      final response = await apiClient.post(path, query);

      if (response is List) {
        // 문서가 있는 항목만 필터링 (readTime 제외)
        final documents =
            response.where((doc) => doc['document'] != null).toList();
        return documents.length;
      } else {
        return 0; // 비정상적 응답
      }
    } catch (e) {
      throw Exception('친구 수를 가져오는 데 실패했습니다: $e');
    }
  }

  // 친구 삭제 함수
  static Future<void> deleteFriend(String targetUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    const path = ':runQuery';

    final query = {
      "structuredQuery": {
        "from": [
          {"collectionId": "friendships"}
        ],
        "where": {
          "compositeFilter": {
            "op": "OR",
            "filters": [
              {
                "compositeFilter": {
                  "op": "AND",
                  "filters": [
                    {
                      "fieldFilter": {
                        "field": {"fieldPath": "userId1"},
                        "op": "EQUAL",
                        "value": {"stringValue": currentUserId}
                      }
                    },
                    {
                      "fieldFilter": {
                        "field": {"fieldPath": "userId2"},
                        "op": "EQUAL",
                        "value": {"stringValue": targetUserId}
                      }
                    }
                  ]
                }
              },
              {
                "compositeFilter": {
                  "op": "AND",
                  "filters": [
                    {
                      "fieldFilter": {
                        "field": {"fieldPath": "userId1"},
                        "op": "EQUAL",
                        "value": {"stringValue": targetUserId}
                      }
                    },
                    {
                      "fieldFilter": {
                        "field": {"fieldPath": "userId2"},
                        "op": "EQUAL",
                        "value": {"stringValue": currentUserId}
                      }
                    }
                  ]
                }
              }
            ]
          }
        },
        "limit": 1
      }
    };

    try {
      final response = await ApiClient().post(path, query);

      if (response is List && response.isNotEmpty) {
        final documentPath = response.first['document']['name'];
        final friendshipId = documentPath.split('/').last;

        await ApiClient().delete('/friendships/$friendshipId');
      } else {
        throw Exception('친구 관계를 찾을 수 없습니다.');
      }
    } catch (e) {
      throw Exception('친구 삭제 실패: $e');
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

  static Future<Capsule> getCapsule(String capsuleId) async {
    final path = '/capsules/$capsuleId';
    try {
      final response = await apiClient.get(path);
      final Capsule capsule = Capsule.fromJson(capsuleId, response);
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
