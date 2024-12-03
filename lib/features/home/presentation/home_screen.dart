import 'package:flutter/material.dart';
import 'package:timea/common/widgets/app_bar.dart';
import 'package:timea/common/widgets/ball_drop_widget.dart';
import 'package:timea/features/home/presentation/envelope_form_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> capsules;
  final bool isLoading;
  final Function(Map<String, dynamic>) onAddCapsule;
  final Function() loadCapsules;
  const HomeScreen({
    super.key,
    required this.capsules,
    required this.isLoading,
    required this.onAddCapsule,
    required this.loadCapsules,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TimeAppBar(
        title: '기억 상자',
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFF4E0),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnvelopeFormScreen(
              capsules: capsules,
              onSubmit: (newCapsule) {
                onAddCapsule(newCapsule); // 새로운 캡슐 추가
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
                      '기억 상자가 비어 있어요.\n당신의 이야기를 담아주세요. 💌',
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
                  loadCapsules: loadCapsules,
                ),
    );
  }
}
