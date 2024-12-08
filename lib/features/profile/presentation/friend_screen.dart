import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timea/common/widgets/app_bar.dart';
import 'package:timea/core/services/firestore_service.dart';

class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  final TextEditingController _nicknameController = TextEditingController();

  RxList<Map<String, dynamic>> friends = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> sentRequests = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> incomingRequests = <Map<String, dynamic>>[].obs;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _loadRequests();
  }

  Future<void> _refreshData() async {
    try {
      friends.value = await FirestoreService.getFriends();
      sentRequests.value = await FirestoreService.getFriendRequests();
      incomingRequests.value =
          await FirestoreService.getIncomingFriendRequests();
    } catch (e) {
      _showSnackbar('데이터 새로고침 실패', e.toString());
    }
  }

  Future<void> _loadFriends() async {
    try {
      friends.value = await FirestoreService.getFriends();
    } catch (e) {
      _showSnackbar('친구 목록 불러오기 실패', e.toString());
    }
  }

  Future<void> _loadRequests() async {
    try {
      sentRequests.value = await FirestoreService.getFriendRequests();
      incomingRequests.value =
          await FirestoreService.getIncomingFriendRequests();
    } catch (e) {
      _showSnackbar('요청 목록 불러오기 실패', e.toString());
    }
  }

  Future<void> _addFriend() async {
    if (_nicknameController.text.trim().isEmpty) return;

    try {
      final targetUser = await FirestoreService.findUserByNickname(
          _nicknameController.text.trim());
      if (targetUser == null) {
        _showSnackbar('오류', '해당 닉네임의 사용자를 찾을 수 없습니다.');
        return;
      }
      await FirestoreService.sendFriendRequest(targetUser.id);
      _showSnackbar('성공', '친구 요청을 보냈습니다.');
      _nicknameController.clear();
      _loadRequests();
    } catch (e) {
      _showSnackbar('오류', e.toString());
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    await FirestoreService.cancelFriendRequest(requestId);
    _showSnackbar('성공', '친구 요청을 취소했습니다.');
    _loadRequests();
  }

  Future<void> _acceptRequest(String requestId) async {
    await FirestoreService.acceptFriendRequest(requestId);
    _showSnackbar('성공', '친구 요청을 수락했습니다.');
    _loadFriends();
    _loadRequests();
  }

  Future<void> _rejectRequest(String requestId) async {
    await FirestoreService.rejectFriendRequest(requestId);
    _showSnackbar('성공', '친구 요청을 거절했습니다.');
    _loadRequests();
  }

  Future<void> _deleteFriend(String friendId) async {
    await FirestoreService.deleteFriend(friendId);
    _showSnackbar('성공', '친구를 삭제했습니다.');
    _loadFriends();
  }

  void _showSnackbar(String title, String message) {
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TimeAppBar(
        title: '친구 관리',
        backButton: true,
      ),
      body: Column(
        children: [
          // 닉네임으로 친구 추가
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: BoxDecoration(
                color: context.theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        hintText: '닉네임으로 친구 추가',
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                      onPressed: _addFriend, icon: const Icon(Icons.person_add))
                ],
              ),
            ),
          ),
          // 탭 화면
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.black,
                    indicatorWeight: 2,
                    tabs: [
                      Tab(icon: Icon(Icons.people), text: '친구'),
                      Tab(icon: Icon(Icons.send), text: '보낸 요청'),
                      Tab(icon: Icon(Icons.inbox), text: '받은 요청'),
                    ],
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshData,
                      child: TabBarView(
                        children: [
                          // 친구 목록
                          Obx(() => ListView.builder(
                                itemCount: friends.length,
                                itemBuilder: (context, index) {
                                  final friend = friends[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 12),
                                    elevation: 1, // 카드의 입체감
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          8), // 카드 모서리 둥글게
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          friend['profileImage'] ??
                                              'https://via.placeholder.com/150',
                                        ),
                                      ),
                                      title: Text(
                                        friend['nickname'] ?? '알 수 없는 사용자',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      trailing: TextButton(
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero, // 내부 패딩 제거
                                          minimumSize:
                                              const Size(30, 20), // 최소 크기 설정
                                          tapTargetSize: MaterialTapTargetSize
                                              .shrinkWrap, // 터치 영역 최소화
                                        ),
                                        onPressed: () =>
                                            _deleteFriend(friend['id']),
                                        child: const Text(
                                          '삭제',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )),

                          // 내가 보낸 요청 (보낸 친구 요청)
                          Obx(() => ListView.builder(
                                itemCount: sentRequests.length,
                                itemBuilder: (context, index) {
                                  final request = sentRequests[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 8),
                                    child: Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ListTile(
                                        title: Text(request['nickname'] ??
                                            '알 수 없는 사용자'),
                                        subtitle: const Text('친구 요청 보냄'),
                                        trailing: TextButton(
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(30, 20),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          onPressed: () =>
                                              _cancelRequest(request['id']),
                                          child: const Text(
                                            '취소',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )),

                          // 내가 받은 요청 (친구 요청 받음)
                          Obx(
                            () => ListView.builder(
                              itemCount: incomingRequests.length,
                              itemBuilder: (context, index) {
                                final request = incomingRequests[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                          request['nickname'] ?? '알 수 없는 사용자'),
                                      subtitle: const Text('친구 요청 받음'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(30, 20),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            onPressed: () =>
                                                _acceptRequest(request['id']),
                                            child: const Text(
                                              '수락',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(30, 20),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            onPressed: () =>
                                                _rejectRequest(request['id']),
                                            child: const Text(
                                              '거절',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
