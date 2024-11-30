import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 3,
        shadowColor: Colors.black12,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Get.offAllNamed('/login');
          },
          child: const Text('Logout'),
        ),
      ),
    );
  }
}
