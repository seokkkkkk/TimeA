import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:timea/common/widgets/app_bar.dart';
import 'package:timea/common/widgets/capsule_dialog.dart';
import 'package:timea/core/controllers/geolocation_controller.dart';

class MapScreen extends StatefulWidget {
  final bool showAppBar;
  final bool isLoading;
  final List<Map<String, dynamic>> capsules;

  const MapScreen({
    super.key,
    this.showAppBar = true,
    this.isLoading = false,
    this.capsules = const [],
  });

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  NaverMapController? _mapController;
  final locationController = Get.find<GeolocationController>();

  @override
  void initState() {
    super.initState();

    // 초기 위치 설정 및 스트림 구독
    locationController.getLocation();
    locationController.currentPosition.listen((position) {
      if (position != null) {
        updateLocationMarker(position);
      }
    });
  }

  @override
  void dispose() {
    // 위치 스트림 구독 취소
    locationController.positionStream.value?.cancel();
    super.dispose();
  }

  void updateLocationMarker(Position position) {
    if (_mapController != null) {
      final locationOverlay = _mapController?.getLocationOverlay();
      if (locationOverlay != null) {
        locationOverlay.setIsVisible(true);
        locationOverlay.setPosition(
          NLatLng(
            position.latitude,
            position.longitude,
          ),
        );
      }
    }
  }

  void addCapsuleOverlays() {
    if (_mapController != null) {
      for (final capsule in widget.capsules) {
        final bool isUnlocked = capsule['unlockedAt'] != null; // 잠금 상태 확인
        final DateTime date = (capsule['canUnlockedAt'] as Timestamp).toDate();
        final isUnlockable = !isUnlocked &&
            date.isBefore(DateTime.now()) &&
            canUnlock(capsule['location']);
        final marker = NMarker(
          id: 'capsule_${capsule['id']}',
          position: NLatLng(
            capsule['location'].latitude,
            capsule['location'].longitude,
          ),
          icon: capsule['unlockedAt'] != null
              ? const NOverlayImage.fromAssetImage(
                  'assets/images/unlocked-ball.png')
              : isUnlockable
                  ? const NOverlayImage.fromAssetImage(
                      'assets/images/unlockable-ball.png')
                  : const NOverlayImage.fromAssetImage(
                      'assets/images/locked-ball.png'),
          anchor: const NPoint(0.5, 0.5), // 마커 중심 정렬
          size: const Size(30, 30),
        );

        marker.setOnTapListener((overlay) {
          showCapsuleDetails(capsule);
        });

        _mapController?.addOverlay(marker);
      }
    }
  }

  void moveToCurrentLocation() {
    final currentPosition = locationController.currentPosition.value;
    if (_mapController != null && currentPosition != null) {
      final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
        target: NLatLng(
          currentPosition.latitude,
          currentPosition.longitude,
        ),
        zoom: 15, // 원하는 줌 레벨
      );
      cameraUpdate.setAnimation(
          animation: NCameraAnimation.easing,
          duration: const Duration(seconds: 1));

      _mapController?.updateCamera(cameraUpdate);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 위치 정보를 가져올 수 없습니다.')),
      );
    }
  }

  bool canUnlock(Position position) {
    final currentPosition = locationController.currentPosition.value;
    if (currentPosition == null) {
      return false;
    }

    final distance = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      position.latitude,
      position.longitude,
    );

    return distance < 25; // 100m 이내에 있을 때만 언락 가능
  }

  void showCapsuleDetails(Map<String, dynamic> capsule) {
    showDialog(
      context: context,
      builder: (context) {
        final bool isUnlocked = capsule['unlockedAt'] != null; // 잠금 상태 확인
        final String title = capsule['title'] ?? '캡슐 정보';
        final String content = capsule['content'] ?? '내용이 없습니다.';
        final String imageUrl = capsule['imageUrl'] ?? '';
        final DateTime date = (capsule['canUnlockedAt'] as Timestamp).toDate();

        final isUnlockable = !isUnlocked &&
            date.isBefore(DateTime.now()) &&
            canUnlock(capsule['location']);

        return CapsuleDetailsDialog(
          title: title,
          content: content,
          imageUrl: imageUrl,
          date: date,
          locationMessage: '',
          isUnlocked: isUnlocked,
          isUnlockable: isUnlockable,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? const TimeAppBar(
              title: '지도 🗺️',
            )
          : null,
      body: widget.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                Obx(
                  () {
                    final currentPosition =
                        locationController.currentPosition.value;
                    if (currentPosition == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return NaverMap(
                      options: NaverMapViewOptions(
                        initialCameraPosition: NCameraPosition(
                          target: NLatLng(
                            currentPosition.latitude,
                            currentPosition.longitude,
                          ),
                          zoom: 15,
                        ),
                        consumeSymbolTapEvents: true,
                      ),
                      onMapReady: (controller) {
                        _mapController = controller;
                        updateLocationMarker(currentPosition);
                        addCapsuleOverlays(); // 지도 준비 완료 후 캡슐 오버레이 추가
                      },
                      forceGesture: false,
                      onMapTapped: (point, latLng) {
                        print('Map tapped at: $latLng');
                      },
                      onSymbolTapped: (symbolInfo) {
                        print('Symbol tapped: $symbolInfo');
                      },
                    );
                  },
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: moveToCurrentLocation,
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
    );
  }
}
