import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CardBuilder extends StatelessWidget {
  final List<Map<String, dynamic>> capsules;
  final String Function(DateTime) calculateDday;

  const CardBuilder({
    super.key,
    required this.capsules,
    required this.calculateDday,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      itemCount: capsules.length,
      controller: PageController(viewportFraction: 0.6),
      itemBuilder: (context, index) {
        final capsule = capsules[index];
        final unlockDate = (capsule['canUnlockedAt'] as Timestamp).toDate();

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          color: Colors.white,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capsule['title'] ?? '제목 없음',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('yyyy년 MM월 dd일').format(unlockDate),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  calculateDday(unlockDate),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
