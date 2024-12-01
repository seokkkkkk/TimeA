import 'package:flutter/material.dart';
import 'package:timea/common/widgets/app_bar.dart';
import 'package:timea/common/widgets/ball_drop_widget.dart';
import 'package:timea/core/services/firestore_service.dart';
import 'package:timea/features/home/presentation/envelope_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> capsules = []; // 캡슐 데이터를 저장
  bool isLoading = true; // 로딩 상태

  @override
  void initState() {
    super.initState();
    _loadCapsules(); // 초기 캡슐 데이터 로드
  }

  Future<void> _loadCapsules() async {
    try {
      final data =
          await FirestoreService.getAllCapsules(); // Firestore에서 캡슐 데이터 가져오기
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
    return Scaffold(
      appBar: const TimeAppBar(
        title: '기억 캡슐 📦',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnvelopeFormScreen(
              onSubmit: (newCapsule) {
                Navigator.of(context).pop(); // 이전 화면으로 돌아가기
                _addCapsule(newCapsule); // 새로운 캡슐 추가
              },
            ),
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 0),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/envelope.png',
            width: 32,
            height: 32,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : capsules.isEmpty
              ? Center(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '텅 빈 캡슐이 기다리고 있어요.\n당신의 이야기를 담아주세요. 💌',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '저장된 캡슐은 지정된 시간과 공간에서 열립니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ))
              : BallDropWidget(
                  capsules: capsules,
                ),
    );
  }
}
