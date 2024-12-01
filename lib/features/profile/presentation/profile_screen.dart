import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timea/common/widgets/app_bar.dart';
import 'package:timea/core/services/firebase_auth_service.dart';
import 'package:timea/core/services/firestore_service.dart';
import 'package:timea/features/profile/%08widget/card_builder.dart';

class ProfileScreen extends StatefulWidget {
  final List<Map<String, dynamic>> capsules;
  final bool isLoading;

  const ProfileScreen({
    super.key,
    required this.capsules,
    required this.isLoading,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _profileImageUrl;
  String? _nickname;
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // Firestore에서 프로필 데이터 로드
  Future<void> _loadProfileData() async {
    if (_currentUser != null) {
      try {
        final userDoc = await FirestoreService.getUserProfile();
        if (userDoc != null) {
          setState(() {
            _profileImageUrl = userDoc['profileImage'] as String?;
            _nickname = userDoc['nickname'] as String?;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 데이터를 불러오지 못했습니다: $e')),
        );
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authService = FirebaseAuthService();
    try {
      await authService.logout();
      Get.offAllNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 실패: $e')),
      );
    }
  }

  String _calculateDday(DateTime targetDate) {
    final now = DateTime.now();
    final difference = targetDate.difference(now).inDays;

    if (difference > 0) {
      return 'D-$difference';
    } else if (difference == 0) {
      return 'D-Day';
    } else {
      return 'D+${-difference}';
    }
  }

  @override
  Widget build(BuildContext context) {
// 곧 만날 기억 캡슐
    final soonCapsules = widget.capsules.where((capsule) {
      final unlockDate = (capsule['canUnlockedAt'] as Timestamp).toDate();
      final unlockedAt = (capsule['unlockedAt'] as Timestamp?)?.toDate();
      return unlockDate.isAfter(DateTime.now()) &&
          unlockDate.isBefore(DateTime.now().add(const Duration(days: 7))) &&
          unlockedAt == null;
    }).toList()
      ..sort((a, b) {
        final dateA = (a['canUnlockedAt'] as Timestamp).toDate();
        final dateB = (b['canUnlockedAt'] as Timestamp).toDate();
        return dateA.compareTo(dateB);
      });

    // 내가 연 기억 캡슐
    final openedCapsules = widget.capsules.where((capsule) {
      final unlockedAt = (capsule['unlockedAt'] as Timestamp?)?.toDate();
      return unlockedAt != null;
    }).toList()
      ..sort((a, b) {
        final dateA =
            (a['unlockedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final dateB =
            (b['unlockedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return dateB.compareTo(dateA); // 최근에 연 캡슐 순으로 정렬
      });

    // 열지 않은 기억 캡슐
    final overdueCapsules = widget.capsules.where((capsule) {
      final unlockDate = (capsule['canUnlockedAt'] as Timestamp).toDate();
      final unlockedAt = (capsule['unlockedAt'] as Timestamp?)?.toDate();
      return unlockDate.isBefore(DateTime.now()) && unlockedAt == null;
    }).toList()
      ..sort((a, b) {
        final dateA = (a['canUnlockedAt'] as Timestamp).toDate();
        final dateB = (b['canUnlockedAt'] as Timestamp).toDate();
        return dateA.compareTo(dateB); // 가장 오래된 캡슐 순으로 정렬
      });

    // 내 모든 기억 캡슐
    final allCapsules = List<Map<String, dynamic>>.from(widget.capsules);

    return Scaffold(
      appBar: const TimeAppBar(title: '프로필 🧑‍💼'),
      body: widget.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 프로필 이미지
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : const AssetImage('assets/icons/logo.png')
                            as ImageProvider,
                  ),
                  const SizedBox(height: 12),
                  // 닉네임과 수정 버튼
                  Column(
                    children: [
                      Text(
                        _nickname ?? '',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 1),
                      GestureDetector(
                        onTap: () {
                          // /profileSetup 페이지로 이동
                          Get.toNamed('/profileSetup');
                        },
                        child: const Text(
                          '프로필 수정',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFC0C0C0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 기한이 지난 기억 캡슐 리스트
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '당신을 기다리는 기억 캡슐',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: overdueCapsules.isEmpty
                        ? const Center(
                            child: Text(
                              '기한이 지난 캡슐이 없습니다.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : CardBuilder(
                            capsules: overdueCapsules,
                            calculateDday: _calculateDday),
                  ),
                  const SizedBox(height: 24),
                  // D-DAY 임박 기억 캡슐 리스트
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '곧 만날 기억 캡슐',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: soonCapsules.isEmpty
                        ? const Center(
                            child: Text(
                              '곧 열릴 캡슐이 없습니다.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : CardBuilder(
                            capsules: soonCapsules,
                            calculateDday: _calculateDday),
                  ),
                  const SizedBox(height: 24),
                  // 열린 기억 캡슐 리스트
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '열린 기억 캡슐',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: openedCapsules.isEmpty
                        ? const Center(
                            child: Text(
                              '아직 열린 캡슐이 없습니다.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : CardBuilder(
                            capsules: openedCapsules,
                            calculateDday: _calculateDday),
                  ),
                  const SizedBox(height: 24),
                  // 모든 기억 캡슐 리스트
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '나의 모든 기억 캡슐',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: allCapsules.isEmpty
                        ? const Center(
                            child: Text(
                              '저장된 캡슐이 없습니다.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : CardBuilder(
                            capsules: allCapsules,
                            calculateDday: _calculateDday),
                  ),
                  const SizedBox(height: 24),
                  // 약관 및 로그아웃
                  ListTile(
                    title: const Text(
                      '약관 및 개인정보',
                      style: TextStyle(
                          fontSize: 14,
                          color: Color.fromARGB(255, 97, 97, 97),
                          fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      // 약관 페이지로 이동
                    },
                  ),
                  ListTile(
                    title: const Text(
                      '로그아웃',
                      style: TextStyle(
                          fontSize: 14,
                          color: Color.fromARGB(255, 97, 97, 97),
                          fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      _handleLogout(context);
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
