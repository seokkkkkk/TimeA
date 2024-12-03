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
  final bool isLoading;
  const MapScreen({super.key, required this.capsules, required this.isLoading});

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

  StreamSubscription<Position>? _positionStreamSubscription;

  late final CameraPosition _initialPosition;

  final RxSet<Marker> _markers = <Marker>{}.obs;

  Stream<Position> get currentPositionStream => Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3, // 최소 거리 변화 감지 설정
      ));

  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    _subscribeToPositionStream();
    _initializeMap();
  }

  void _subscribeToPositionStream() {
    _positionStreamSubscription = currentPositionStream.listen((position) {
      currentPosition = position;
      _generateMarkerIcons();
      // 필요시 UI 갱신
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
      currentPosition!.latitude,
      currentPosition!.longitude,
      markerPosition.latitude,
      markerPosition.longitude,
    );

    if (distance <= 5) {
      compassSubscription.cancel();
      return '기억 캡슐이 근처에 있습니다.'.obs;
    }

    final bearing = Geolocator.bearingBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
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
      _stopTracking();
    } else {
      _startTracking();
    }
    isTracking.value = !isTracking.value;
  }

  void _startTracking() {
    _positionStreamSubscription =
        Geolocator.getPositionStream().listen((position) async {
      if (isTracking.value) {
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 18,
            ),
          ),
        );
      }
    });
  }

  void _stopTracking() {
    isTracking = false.obs; // 추적 중지
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isMapReady.value
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
                      _stopTracking(); // 맵을 클릭하면 추적 중지
                    },
                    onCameraMove: (position) {
                      _stopTracking(); // 카메라 이동 시 추적 중지
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

  Future<void> _generateMarkerIcons() async {
    final markers = <Marker>{};
    for (final capsule in widget.capsules) {
      if (capsule['location'] == null || capsule['canUnlockedAt'] == null) {
        continue; // 데이터가 유효하지 않으면 건너뜁니다.
      }
      final icon = await _buildMarkerIcon(
        capsule['isUnlocked'] ?? false,
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
            _onMarkerTap(capsule);
            _stopTracking();
          },
        ),
      );
    }
    _markers.assignAll(markers);
  }

  Future<BitmapDescriptor> _buildMarkerIcon(
      bool isUnlocked, GeoPoint location, DateTime canUnlockDate) async {
    final distance = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      location.latitude,
      location.longitude,
    );

    final canUnlock = canUnlockDate.isBefore(DateTime.now());

    final assetPath = isUnlocked
        ? 'assets/images/unlocked-ball.png'
        : distance <= 5 && canUnlock
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

    final compassSubscription = FlutterCompass.events!.listen((event) {
      _getMarkerDescription(
          GeoPoint(markerPosition.latitude, markerPosition.longitude));
    });

    final locationSubscription =
        Geolocator.getPositionStream().listen((position) {
      _getMarkerDescription(
          GeoPoint(markerPosition.latitude, markerPosition.longitude));
    });

    showDialog(
      context: context,
      builder: (context) {
        return Obx(() {
          RxString locationMessage = _getMarkerDescription(capsule['location']);
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
                _getMarkerDescription(capsule['location'])
                    .value
                    .contains('기억 캡슐이 근처에 있습니다.'),
            onUnlock: () async {
              try {
                await FirestoreService.updateCapsuleStatus(
                  capsuleId: capsule['id'],
                  unlockedAt: DateTime.now(),
                );
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
    _positionStreamSubscription?.cancel(); // 위치 추적 스트림 해제
    super.dispose();
  }
}
