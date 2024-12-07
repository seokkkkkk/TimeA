import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timea/common/widgets/app_bar.dart';
import 'package:timea/features/notification/controllers/notification_controller.dart';

class NotificationScreen extends StatelessWidget {
  final NotificationController controller = Get.put(NotificationController());

  NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TimeAppBar(
        title: '알림',
        backButton: true,
        notification: false,
      ),
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return const Center(child: Text('알림이 없습니다.'));
        }

        return ListView.builder(
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            final isRead = notification['reading'] as bool;

            return ListTile(
              visualDensity:
                  const VisualDensity(horizontal: -4, vertical: -4), // 간격 축소
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8), // 패딩 조절
              title: Text(notification['title']),
              subtitle: Text(notification['message']),
              tileColor: isRead ? Colors.grey[200] : Colors.white,
              onTap: () {
                controller.markAsRead(notification['id']);
                Get.back();
              },
              trailing: SizedBox(
                width: 24, // trailing의 크기 축소
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero, // 버튼 내부 패딩 제거
                  icon: const Icon(Icons.close, size: 20), // 아이콘 크기 조절
                  onPressed: () {
                    controller.deleteNotification(notification['id']);
                  },
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
