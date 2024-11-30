import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timea/common/controllers/navigtaion_bar_controller.dart';
import 'package:timea/common/widgets/navigation_bar.dart';
import 'package:timea/features/home/presentation/home_screen.dart';
import 'package:timea/features/map/presentation/map_screen.dart';
import 'package:timea/features/profile/presentation/profile_screen.dart';

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  static List<Widget> pages = [
    const MapScreen(),
    const HomeScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Get.put(TimeNavigtaionBarController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.colorScheme.surface,
      body: Obx(() =>
          pages[Get.find<TimeNavigtaionBarController>().currentIndex.value]),
      bottomNavigationBar: const TimeNavigationBar(),
    );
  }
}
