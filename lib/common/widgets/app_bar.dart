import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timea/features/notification/controllers/notification_controller.dart';

class TimeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool notification;
  final bool backButton;

  const TimeAppBar({
    super.key,
    required this.title,
    this.notification = true,
    this.backButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final NotificationController notificationController =
        Get.put(NotificationController());

    return AppBar(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 3,
      shadowColor: Colors.black12,
      leading: backButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          : Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Image.asset(
                'assets/icons/logo.png',
              ),
            ),
      actions: [
        if (notification)
          Obx(() {
            final count = notificationController.notificationCount.value;

            return Stack(
              children: [
                IconButton(
                  onPressed: () {
                    Get.toNamed('/notification');
                  },
                  icon: const Icon(
                    Icons.notifications_none,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    right: 12,
                    bottom: 8,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
