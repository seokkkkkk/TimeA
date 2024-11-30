import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
