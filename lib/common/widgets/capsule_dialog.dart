import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timea/common/widgets/capsule_animation.dart';
import 'package:timea/common/widgets/snack_bar_util.dart';

class CapsuleDetailsDialog extends StatelessWidget {
  final String title;
  final String? content;
  final String? imageUrl;
  final DateTime date;
  final RxString locationMessage; // RxString으로 변경
  final String locationString;
  final bool isUnlocked;
  final bool isUnlockable;
  final VoidCallback? onUnlock;

  const CapsuleDetailsDialog({
    super.key,
    required this.title,
    this.content,
    this.imageUrl,
    required this.date,
    required this.locationMessage,
    required this.locationString,
    required this.isUnlocked,
    required this.isUnlockable,
    this.onUnlock,
  });

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
          if (isUnlocked && (imageUrl != null) && imageUrl!.isNotEmpty) ...[
            Column(
              children: [
                Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (BuildContext context, Widget child,
                      ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) {
                      return child; // 이미지가 로드되면 child 반환
                    }
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null, // 진행률 계산
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('이미지를 불러올 수 없습니다.');
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
            if ((content != null) && content!.isNotEmpty) ...[
              Text(
                content!,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Text(fixedDate),
          Obx(() => Text(
              locationMessage.value)), // locationMessage를 Obx로 감싸서 실시간 업데이트
        ],
      ),
      actions: [
        if (!isUnlocked)
          TextButton(
            onPressed: isUnlockable
                ? () {
                    onUnlock?.call();
                    Navigator.of(context, rootNavigator: true).pop();
                    Get.to(() => const CapsuleAnimation());
                  }
                : () {
                    SnackbarUtil.showInfo(
                      '잠금 해제 불가',
                      '캡슐을 열기 위한 조건이 충족되지 않았습니다.',
                    );
                  },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                (states) =>
                    isUnlockable ? const Color(0xFFFFD8C2) : Colors.grey,
              ),
              foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                (states) =>
                    isUnlockable ? const Color(0xFF1A1A1A) : Colors.white,
              ),
            ),
            child: const Text("잠금 해제"),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
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
