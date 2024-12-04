import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timea/common/controllers/navigtaion_bar_controller.dart';
import 'package:timea/common/widgets/navigation_bar.dart';
import 'package:timea/core/services/firestore_service.dart';
import 'package:timea/features/home/presentation/home_screen.dart';
import 'package:timea/features/map/presentation/map_screen.dart';
import 'package:timea/features/profile/presentation/profile_screen.dart';

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  List<Map<String, dynamic>> capsules = []; // 캡슐 데이터
  Map<String, dynamic> userInfo = {}; // 유저 정보
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCapsules(null); // 캡슐 데이터 로드
    Get.put(TimeNavigtaionBarController());
  }

  Future<List<Map<String, dynamic>>?> _loadCapsules(String? capsuleId) async {
    try {
      List<Map<String, dynamic>> updatedCapsules = [];
      if (capsuleId != null) {
        // 단일 캡슐 데이터 로드
        final data = await FirestoreService.getCapsule(capsuleId);
        updatedCapsules = capsules.map((capsule) {
          if (capsule['id'] == capsuleId) {
            return data;
          }
          return capsule;
        }).toList();
      } else {
        // 모든 캡슐 데이터 로드
        updatedCapsules = await FirestoreService.getAllCapsules();
      }
      // 상태 업데이트
      setState(() {
        capsules = updatedCapsules;
      });
      return updatedCapsules;
    } catch (e) {
      // 에러 상태 처리
      setState(() {
        isLoading = false;
      });
      _showError('캡슐 데이터 로드 실패: $e');
      return null; // 명확히 null 반환
    } finally {
      // 로딩 상태 종료
      setState(() {
        isLoading = false;
      });
    }
  }

  void _addCapsule(Map<String, dynamic> newCapsule) {
    setState(() {
      capsules.add(newCapsule); // 새로운 캡슐 추가
    });
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("오류"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      MapScreen(
        capsules: capsules,
        isLoading: isLoading,
        loadCapsules: _loadCapsules,
      ),
      HomeScreen(
        capsules: capsules,
        isLoading: isLoading,
        onAddCapsule: _addCapsule,
        loadCapsules: _loadCapsules,
      ),
      ProfileScreen(
        capsules: capsules,
        isLoading: isLoading,
      ),
    ];

    return Scaffold(
      backgroundColor: context.theme.colorScheme.surface,
      body: Obx(() =>
          pages[Get.find<TimeNavigtaionBarController>().currentIndex.value]),
      bottomNavigationBar: const TimeNavigationBar(),
    );
  }
}
