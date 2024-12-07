import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timea/common/widgets/app_bar.dart';
import 'package:timea/common/widgets/snack_bar_util.dart';
import 'package:timea/core/services/firestore_service.dart';

class FriendManagementScreen extends StatefulWidget {
  const FriendManagementScreen({super.key});

  @override
  FriendManagementScreenState createState() => FriendManagementScreenState();
}

class FriendManagementScreenState extends State<FriendManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RxList<Map<String, dynamic>> _friends = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _friendRequests =
      <Map<String, dynamic>>[].obs;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _loadFriendRequests();
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await FirestoreService.getUserProfile();
      _friends.value = List<Map<String, dynamic>>.from(
        (friends?.data() as Map<String, dynamic>?)?['friends'] ?? [],
      );
    } catch (e) {
      SnackbarUtil.showError('성공', '친구 목록을 불러오는 데 실패했습니다.');
    }
  }

  Future<void> _loadFriendRequests() async {
    try {
      final requests = await FirestoreService.getFriendRequests();
      _friendRequests.value = requests;
    } catch (e) {
      SnackbarUtil.showError('성공', '친구 요청 목록을 불러오는 데 실패했습니다.');
    }
  }

  Future<void> _addFriend(String nickname) async {
    try {
      await FirestoreService.sendFriendRequest(nickname);
      SnackbarUtil.showInfo('성공', '친구 요청을 보냈습니다.');
      _searchController.clear();
    } catch (e) {
      SnackbarUtil.showError('성공', e.toString());
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      await FirestoreService.acceptFriendRequest(requestId);
      SnackbarUtil.showInfo('성공', '친구 요청을 수락했습니다.');
      _loadFriends();
      _loadFriendRequests();
    } catch (e) {
      SnackbarUtil.showError('성공', e.toString());
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await FirestoreService.rejectFriendRequest(requestId);
      SnackbarUtil.showInfo('성공', '친구 요청을 거절했습니다.');
      _loadFriendRequests();
    } catch (e) {
      SnackbarUtil.showError('성공', e.toString());
    }
  }

  Future<void> _deleteFriend(String friendId) async {
    try {
      await FirestoreService.deleteFriend(friendId);
      SnackbarUtil.showInfo('성공', '친구를 삭제했습니다.');
      _loadFriends();
    } catch (e) {
      SnackbarUtil.showError('성공', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TimeAppBar(
        title: '친구 관리',
        backButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 친구 추가 검색 바
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: '닉네임으로 친구 요청',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _addFriend(_searchController.text),
                    icon: const Icon(Icons.person_add),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // 탭 바
            DefaultTabController(
              length: 2,
              child: Expanded(
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.black,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: [
                        Tab(text: '친구'),
                        Tab(text: '친구 요청'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // 친구 탭
                          Obx(() => ListView.builder(
                                itemCount: _friends.length,
                                itemBuilder: (context, index) {
                                  final friend = _friends[index];
                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage: NetworkImage(
                                            friend['fromProfileImage']),
                                      ),
                                      title: Text(friend['fromNickname']),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () =>
                                            _deleteFriend(friend['id']),
                                      ),
                                    ),
                                  );
                                },
                              )),
                          // 친구 요청 탭
                          Obx(() => ListView.builder(
                                itemCount: _friendRequests.length,
                                itemBuilder: (context, index) {
                                  final request = _friendRequests[index];
                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage: NetworkImage(
                                            request['fromProfileImage']),
                                      ),
                                      title: Text(request['fromNickname']),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.check),
                                            onPressed: () =>
                                                _acceptRequest(request['id']),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () =>
                                                _rejectRequest(request['id']),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
