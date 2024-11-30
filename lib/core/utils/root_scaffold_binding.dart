import 'package:get/get.dart';
import 'package:timea/core/controllers/geolocation_controller.dart';

class RootScaffoldBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(GeolocationController());
  }
}
