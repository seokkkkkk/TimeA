import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:timea/common/widgets/app_bar.dart';
import 'package:timea/core/controllers/geolocation_controller.dart';

class MapScreen extends StatefulWidget {
  final bool showAppBar;
  const MapScreen({super.key, this.showAppBar = true});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? const TimeAppBar(
              title: '지도 🗺️',
            )
          : null,
      body: Stack(
        children: [
          Obx(
            () {
              final currentPosition = locationController.currentPosition.value;
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
