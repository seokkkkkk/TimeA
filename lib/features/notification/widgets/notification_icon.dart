import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timea/features/notification/controllers/notification_controller.dart';

class NotificationIcon extends StatelessWidget {
  final NotificationController controller = Get.put(NotificationController());

  NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final unreadCount =
          controller.notifications.where((n) => !(n['reading'] as bool)).length;

      return Stack(
        children: [
          const Icon(Icons.notifications, size: 30),
          if (unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      );
    });
  }
}
