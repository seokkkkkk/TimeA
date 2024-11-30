import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:timea/common/widgets/snack_bar_util.dart';

class GeolocationController extends GetxController {
  var currentPosition = Rx<Position?>(null);
  var positionStream = Rx<Stream<Position>?>(null);

  Future<void> getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      SnackbarUtil.showError('권한 오류', '위치 서비스를 활성화해주세요.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      SnackbarUtil.showError('권한 오류', '위치 권한을 허용해주세요.');
      return;
    } else if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        SnackbarUtil.showError('권한 오류', '위치 권한을 허용해주세요.');
        return;
      }
    }

    final position = await Geolocator.getCurrentPosition();
    currentPosition.value = position;

    // 위치 스트림 업데이트
    positionStream.value = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5, // 위치 변화 감지 최소 거리
      ),
    );
  }
}
