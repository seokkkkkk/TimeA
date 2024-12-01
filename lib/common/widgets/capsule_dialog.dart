import 'package:flutter/material.dart';
import 'package:timea/common/widgets/snack_bar_util.dart';

class CapsuleDetailsDialog extends StatelessWidget {
  final String title;
  final String content;
  final String imageUrl;
  final DateTime date;
  final String locationMessage;
  final bool isUnlocked;
  final bool isUnlockable;
  final VoidCallback? onUnlock;

  const CapsuleDetailsDialog({
    super.key,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.date,
    required this.locationMessage,
    required this.isUnlocked,
    required this.isUnlockable,
    this.onUnlock,
  });

  @override
  //date를 년시분까지만 보여주기 위해 date를 String으로 변환

  @override
  Widget build(BuildContext context) {
    final String fixedDate = date.toString().substring(0, 16);
    return AlertDialog(
      title: Text(
        '${isUnlocked ? '🔮' : '🔒'} $title',
      ),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isUnlocked) ...[
            if (imageUrl.isNotEmpty) Image.network(imageUrl, fit: BoxFit.cover),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(fixedDate),
            Text(locationMessage),
          ] else ...[
            const Center(
              child: Icon(
                Icons.lock,
                size: 64,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '이 캡슐은 아직 열리지 않았습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(fixedDate),
            Text(locationMessage),
          ],
        ],
      ),
      actions: [
        if (!isUnlocked)
          TextButton(
            onPressed: isUnlockable ? onUnlock : onUnlock,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                (states) =>
                    isUnlockable ? const Color(0xFFFFD8C2) : Colors.grey,
              ),
              foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                  (states) =>
                      isUnlockable ? const Color(0xFF1A1A1A) : Colors.white),
            ),
            child: const Text("잠금 해제"),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color?>(
              (states) => const Color(0xFFFFE4A3),
            ),
            foregroundColor: WidgetStateProperty.resolveWith<Color?>(
              (states) => const Color(0xFF1A1A1A),
            ),
          ),
          child: const Text("확인"),
        ),
      ],
    );
  }
}
