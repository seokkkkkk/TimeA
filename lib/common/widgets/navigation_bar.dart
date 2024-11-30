import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:timea/common/controllers/navigtaion_bar_controller.dart';

class TimeNavigationBar extends GetView<TimeNavigtaionBarController> {
  const TimeNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: context.theme.colorScheme.primary.withOpacity(0.5),
            blurRadius: 5,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Obx(
          () => BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changeIndex,
            selectedItemColor: context.theme.colorScheme.onSurface,
            unselectedItemColor: context.theme.colorScheme.onSurfaceVariant,
            unselectedLabelStyle: const TextStyle(fontSize: 10),
            selectedLabelStyle:
                const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                  icon: controller.currentIndex.value == 0
                      ? SvgPicture.asset(
                          'assets/images/menu-map-1.svg',
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            context.theme.colorScheme.onSurface,
                            BlendMode.srcIn,
                          ),
                        )
                      : SvgPicture.asset(
                          'assets/images/menu-map-2.svg',
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            context.theme.colorScheme.onSurfaceVariant,
                            BlendMode.srcIn,
                          ),
                        ),
                  label: "지도"),
              BottomNavigationBarItem(
                  icon: controller.currentIndex.value == 1
                      ? SvgPicture.asset(
                          'assets/images/menu-home-1.svg',
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            context.theme.colorScheme.onSurface,
                            BlendMode.srcIn,
                          ),
                        )
                      : SvgPicture.asset(
                          'assets/images/menu-home-2.svg',
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            context.theme.colorScheme.onSurfaceVariant,
                            BlendMode.srcIn,
                          ),
                        ),
                  label: "홈"),
              BottomNavigationBarItem(
                  icon: controller.currentIndex.value == 2
                      ? SvgPicture.asset(
                          'assets/images/menu-profile-1.svg',
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            context.theme.colorScheme.onSurface,
                            BlendMode.srcIn,
                          ),
                        )
                      : SvgPicture.asset(
                          'assets/images/menu-profile-2.svg',
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            context.theme.colorScheme.onSurfaceVariant,
                            BlendMode.srcIn,
                          ),
                        ),
                  label: "프로필"),
            ],
          ),
        ),
      ),
    );
  }
}
