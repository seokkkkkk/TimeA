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

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              color: isRead ? Colors.grey[200] : Colors.white,
              child: ListTile(
                title: Text(notification['title']),
                subtitle: Text(notification['message']),
                onTap: () {
                  controller.markAsRead(notification['id']);
                  Get.back();
                },
                trailing: SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      controller.deleteNotification(notification['id']);
                    },
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
