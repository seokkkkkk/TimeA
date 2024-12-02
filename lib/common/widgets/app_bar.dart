import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TimeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int notificationCount;
  final bool backButton;

  const TimeAppBar({
    super.key,
    required this.title,
    this.notificationCount = 0, // 알림 개수 (기본값 0)
    this.backButton = false, // 뒤로가기 버튼 여부 (기본값 false)
  });

  @override
  Widget build(BuildContext context) {
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
        Stack(
          children: [
            IconButton(
              onPressed: () {
                Get.toNamed('/notification');
              },
              icon: const Icon(Icons.notifications_none),
            ),
            if (notificationCount > 0)
              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$notificationCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
