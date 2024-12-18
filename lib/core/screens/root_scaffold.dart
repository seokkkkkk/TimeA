import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timea/common/controllers/navigtaion_bar_controller.dart';
import 'package:timea/common/widgets/navigation_bar.dart';
import 'package:timea/core/model/capsule.dart';
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
  List<Capsule> capsules = []; // 캡슐 데이터
  Map<String, dynamic> userInfo = {}; // 유저 정보
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCapsules(); // 캡슐 데이터 로드
    Get.put(TimeNavigtaionBarController());
  }

  Future<void> _loadCapsules() async {
    try {
      List<Capsule> updatedCapsules = await FirestoreService.getAllCapsules();
      setState(() {
        capsules = updatedCapsules;
      });
    } catch (e) {
      _showError('캡슐 데이터 로드 실패: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateCapsules(List<Capsule> updatedCapsules) {
    setState(() {
      capsules = updatedCapsules;
    });
  }

  void _addCapsule(Capsule newCapsule) {
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
      RefreshIndicator(
        onRefresh: _loadCapsules, // 스와이프 새로고침 시 데이터 로드
        child: MapScreen(
          capsules: capsules,
          isLoading: isLoading,
          updateCapsules: updateCapsules,
        ),
      ),
      RefreshIndicator(
        onRefresh: _loadCapsules,
        child: HomeScreen(
          capsules: capsules,
          isLoading: isLoading,
          onAddCapsule: _addCapsule,
          updateCapsules: updateCapsules,
        ),
      ),
      RefreshIndicator(
        onRefresh: _loadCapsules,
        child: ProfileScreen(
          capsules: capsules,
          isLoading: isLoading,
        ),
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
