import 'package:get/get.dart';

class TimeNavigtaionBarController extends GetxController {
  static TimeNavigtaionBarController get to => Get.find();

  final RxInt currentIndex = 1.obs;

  void changeIndex(int index) {
    currentIndex.value = index;
  }
}
