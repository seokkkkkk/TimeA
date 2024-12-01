import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:timea/common/widgets/snack_bar_util.dart';

class GeolocationController extends GetxController {
  // 현재 위치
  final currentPosition = Rx<Position?>(null);

  // 위치 스트림
  final positionStream = Rx<StreamSubscription<Position>?>(null);

  @override
  void onInit() {
    super.onInit();
    getLocation(); // 컨트롤러 초기화 시 위치 정보 가져오기
  }

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

    try {
      // 현재 위치 가져오기
      final position = await Geolocator.getCurrentPosition();
      currentPosition.value = position;

      // 위치 스트림 구독
      startLocationStream();
    } catch (e) {
      SnackbarUtil.showError('오류', '위치 정보를 가져오는 데 실패했습니다.');
    }
  }

  void startLocationStream() {
    // 기존 스트림 구독 중지
    positionStream.value?.cancel();

    // 새 위치 스트림 구독
    positionStream.value = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5, // 위치 변화 감지 최소 거리
      ),
    ).listen((position) {
      currentPosition.value = position;
    });
  }

  @override
  void onClose() {
    // 스트림 구독 중지
    positionStream.value?.cancel();
    super.onClose();
  }
}
