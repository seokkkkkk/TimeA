import 'package:flutter/material.dart';
import 'package:timea/common/widgets/snack_bar_util.dart';
import 'package:timea/core/utils/root_scaffold.dart';

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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
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
            Text("$date"),
            Text(locationMessage),
            const Text("잠금 상태: 해제됨"),
          ] else ...[
            Text("$date"),
            Text(locationMessage),
            const Text("잠금 상태: 잠김"),
          ],
        ],
      ),
      actions: [
        if (!isUnlocked)
          TextButton(
            onPressed: isUnlockable
                ? onUnlock
                : () {
                    SnackbarUtil.showInfo('잠금 해제 불가', '잠금 해제 조건을 확인해주세요.');
                  },
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
