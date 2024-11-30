import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    final locationController = Get.find<GeolocationController>();

    // 초기 위치 가져오기
    locationController.getLocation();

    // 위치 스트림 구독
    locationController.positionStream.listen((stream) {
      stream?.listen((position) {
        updateLocationMarker(position);
      });
    });
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

  @override
  Widget build(BuildContext context) {
    final locationController = Get.find<GeolocationController>();

    return Scaffold(
      appBar: widget.showAppBar
          ? const TimeAppBar(
              title: '지도 🗺️',
            )
          : null,
      body: Obx(
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
                zoom: 14,
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
    );
  }
}
