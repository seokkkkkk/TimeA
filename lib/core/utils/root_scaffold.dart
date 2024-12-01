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
    _loadCapsules(); // 캡슐 데이터 로드
    Get.put(TimeNavigtaionBarController());
  }

  Future<List<Map<String, dynamic>>> _loadCapsules() async {
    try {
      final data = await FirestoreService.getAllCapsules();
      setState(() {
        capsules = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('캡슐 데이터 로드 실패: $e');
    }
    return capsules;
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
