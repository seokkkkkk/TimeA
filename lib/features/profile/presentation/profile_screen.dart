import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:timea/common/widgets/app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TimeAppBar(title: ''),
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
