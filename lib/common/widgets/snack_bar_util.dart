import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class SnackbarUtil {
  // 공통적으로 사용할 Snackbar 함수
  static void showError(String title, String message) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(title, message,
          icon: SvgPicture.asset('assets/images/triangle-alert.svg',
              width: 24, height: 24),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          padding: const EdgeInsets.fromLTRB(32, 16, 16, 16));
    }
  }

  static void showSuccess(String title, String message) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(title, message,
          icon: SvgPicture.asset('assets/images/circle-check.svg',
              width: 24, height: 24),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          padding: const EdgeInsets.fromLTRB(32, 16, 16, 16));
    }
  }

  static void showInfo(String title, String message) {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(title, message,
          icon:
              SvgPicture.asset('assets/images/info.svg', width: 24, height: 24),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE0E0E0),
          colorText: Colors.black,
          padding: const EdgeInsets.fromLTRB(32, 16, 16, 16));
    }
  }
}
