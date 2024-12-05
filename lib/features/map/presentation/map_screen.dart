import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:timea/common/widgets/capsule_dialog.dart';
import 'package:timea/core/controllers/geolocation_controller.dart';
import 'package:timea/core/services/firestore_service.dart';

class MapScreen extends StatefulWidget {
  final List<Map<String, dynamic>> capsules;
  final Function updateCapsules;
  final bool canTap;

  final bool isLoading;
  const MapScreen({
    super.key,
    required this.capsules,
    required this.isLoading,
    required this.updateCapsules,
    this.canTap = true,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  final GeolocationController _geolocationController =
      Get.find<GeolocationController>();

  RxBool isMapReady = false.obs;
  RxBool isTracking = false.obs;

  final RxSet<Marker> _markers = <Marker>{}.obs;

  late final CameraPosition _initialPosition;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _generateMarkerIcons(widget.capsules);
    _geolocationController.subscribeToLocationUpdates((position) {
      _generateMarkerIcons(widget.capsules);
      setState(() {});
    });
  }

  RxString _getMarkerDescription(GeoPoint markerPosition) {
    double deviceHeading = 0.0;
    // 방위각과 위치 데이터 변경 시 메시지 업데이트
    final compassSubscription = FlutterCompass.events!.listen((event) {
      deviceHeading = event.heading ?? 0;
    });

    final distance = Geolocator.distanceBetween(
      _geolocationController.currentPos != null
          ? _geolocationController.currentPos!.latitude
          : 0,
      _geolocationController.currentPos != null
          ? _geolocationController.currentPos!.longitude
          : 0,
      markerPosition.latitude,
      markerPosition.longitude,
    );

    if (distance <= 5) {
      compassSubscription.cancel();
      return '기억 캡슐이 근처에 있습니다.'.obs;
    }

    final bearing = Geolocator.bearingBetween(
      _geolocationController.currentPos != null
          ? _geolocationController.currentPos!.latitude
          : 0,
      _geolocationController.currentPos != null
          ? _geolocationController.currentPos!.longitude
          : 0,
      markerPosition.latitude,
      markerPosition.longitude,
    );

    final relativeBearing = (bearing - deviceHeading + 360) % 360;

    String direction;
    if (relativeBearing >= 315 || relativeBearing < 45) {
      direction = '앞으로';
    } else if (relativeBearing >= 45 && relativeBearing < 135) {
      direction = '오른쪽으로';
    } else if (relativeBearing >= 135 && relativeBearing < 225) {
      direction = '뒤로';
    } else {
      direction = '왼쪽으로';
    }

    String formattedDistance;
    if (distance <= 100) {
      formattedDistance = '${distance.toStringAsFixed(0)}m';
    } else {
      formattedDistance = '${(distance / 1000).toStringAsFixed(1)}km';
    }

    compassSubscription.cancel();

    return '$formattedDistance $direction'.obs;
  }

  Future<void> _initializeMap() async {
    _initialPosition = CameraPosition(
      target: _geolocationController.currentPos != null
          ? LatLng(_geolocationController.currentPos!.latitude,
              _geolocationController.currentPos!.longitude)
          : const LatLng(37.5665, 126.978), // 기본 위치: 서울
      zoom: 18,
    );
    isMapReady.value = true;
  }

  void _toggleTracking() {
    if (isTracking.value) {
      _geolocationController.positionStream.value?.cancel(); // 추적 중지
    } else {
      _geolocationController.subscribeToLocationUpdates((position) async {
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 18,
            ),
          ),
        );
      });
    }
    isTracking.toggle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !widget.isLoading && isMapReady.value
          ? Stack(
              children: [
                // Google Map
                Obx(() {
                  return GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: _initialPosition,
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    markers: _markers.toSet(),
                    onTap: (LatLng position) {
                      _geolocationController.positionStream.value?.cancel();
                      isTracking.value = false;
                    },
                  );
                }),
                // 카메라 이동 버튼
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: _toggleTracking, // 추적 시작/중지 토글
                    backgroundColor: const Color(0xFFFFF4E0), // 추적 상태에 따라 색상 변경
                    child: Icon(
                      isTracking.value
                          ? Icons.location_disabled
                          : Icons.my_location,
                      color: const Color(0xFFFFCC66),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  Future<void> _generateMarkerIcons(
      final List<Map<String, dynamic>> newCapsules) async {
    final markers = <Marker>{};
    for (final capsule in newCapsules) {
      if (capsule['location'] == null || capsule['canUnlockedAt'] == null) {
        continue; // 데이터가 유효하지 않으면 건너뜁니다.
      }

      final icon = await _buildMarkerIcon(
        capsule['unlockedAt'] != null,
        capsule['location'],
        capsule['canUnlockedAt'].toDate(),
      );
      markers.add(
        Marker(
          markerId: MarkerId(capsule['id']),
          position: LatLng(
            capsule['location'].latitude,
            capsule['location'].longitude,
          ),
          icon: icon,
          onTap: () {
            if (widget.canTap) _onMarkerTap(capsule);
            _geolocationController.positionStream.value?.cancel();
            isTracking.value = false;
          },
        ),
      );
    }
    _markers.assignAll(markers);
  }

  Future<BitmapDescriptor> _buildMarkerIcon(
      bool isUnlocked, GeoPoint location, DateTime canUnlockDate) async {
    final distance = Geolocator.distanceBetween(
      _geolocationController.currentPos != null
          ? _geolocationController.currentPos!.latitude
          : 0,
      _geolocationController.currentPos != null
          ? _geolocationController.currentPos!.longitude
          : 0,
      location.latitude,
      location.longitude,
    );

    final canUnlock = canUnlockDate.isBefore(DateTime.now());

    final assetPath = isUnlocked
        ? 'assets/images/unlocked-ball.png'
        : (distance <= 5 && canUnlock)
            ? 'assets/images/unlockable-ball.png'
            : 'assets/images/locked-ball.png';

    // String assetPath = isActive
    //     ? 'assets/images/marker_active.png' // Active state image
    //     : 'assets/images/marker_inactive.png'; // Inactive state image

    // Create and return a BitmapDescriptor using the asset
    return BitmapDescriptor.asset(
      const ImageConfiguration(
        size: Size(24, 24), // Size of the marker icon
      ),
      assetPath,
      imagePixelRatio:
          2.0, // Optional: set the pixel ratio for high-res images,
    );
  }

  void _onMarkerTap(Map<String, dynamic> capsule) async {
    final GoogleMapController controller = await _controller.future;
    final markerPosition = LatLng(
      capsule['location'].latitude,
      capsule['location'].longitude,
    );

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: markerPosition, zoom: 20),
      ),
    );

    final RxString locationMessage = '위치 정보 가져오는 중...'.obs; // RxString 생성

    locationMessage.value = _getMarkerDescription(
            GeoPoint(markerPosition.latitude, markerPosition.longitude))
        .value;

    final compassSubscription = FlutterCompass.events!.listen((event) {
      locationMessage.value = _getMarkerDescription(
              GeoPoint(markerPosition.latitude, markerPosition.longitude))
          .value;
    });

    final locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
      ),
    ).listen((position) {
      locationMessage.value = _getMarkerDescription(
              GeoPoint(markerPosition.latitude, markerPosition.longitude))
          .value;
    });

    showDialog(
      context: context,
      builder: (context) {
        return Obx(() {
          return CapsuleDetailsDialog(
            title: capsule['title'],
            content: capsule['unlockedAt'] != null ? capsule['content'] : null,
            imageUrl:
                capsule['unlockedAt'] != null ? capsule['imageUrl'] : null,
            date: capsule['canUnlockedAt'].toDate(),
            locationMessage: locationMessage,
            locationString: locationMessage.value,
            isUnlocked: capsule['unlockedAt'] != null,
            isUnlockable: (capsule['unlockedAt'] == null) &&
                capsule['canUnlockedAt'].toDate().isBefore(DateTime.now()) &&
                locationMessage.value.contains('기억 캡슐이 근처에 있습니다.'),
            onUnlock: () async {
              try {
                final newCapule = await FirestoreService.updateCapsuleStatus(
                  capsuleId: capsule['id'],
                  unlockedAt: DateTime.now(),
                );
                final newCapsules = widget.capsules
                    .map((c) => c['id'] == newCapule['id'] ? newCapule : c)
                    .toList();
                widget.updateCapsules(newCapsules);
                widget.capsules.clear();
                widget.capsules.addAll(newCapsules);
                await _generateMarkerIcons(newCapsules);
                setState(() {});
              } catch (e) {
                Get.snackbar('오류', '기억 캡슐을 열 수 없습니다.');
              }
            },
          );
        });
      },
    ).then((_) {
      compassSubscription.cancel();
      locationSubscription.cancel();
    });
  }

  @override
  void dispose() {
    _geolocationController.positionStream.value?.cancel();
    super.dispose();
  }
}
