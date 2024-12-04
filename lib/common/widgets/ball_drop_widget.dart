import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timea/common/widgets/capsule_dialog.dart';
import 'package:timea/core/controllers/geolocation_controller.dart';
import 'package:timea/core/services/firestore_service.dart';
import 'dart:math';
import 'ball_physics.dart';
import 'package:timea/common/widgets/ball_painter.dart';

class BallDropWidget extends StatefulWidget {
  final List<Map<String, dynamic>> capsules;
  final Function loadCapsules;
  const BallDropWidget(
      {super.key, required this.capsules, required this.loadCapsules});

  @override
  State<BallDropWidget> createState() => _BallDropWidgetState();
}

class _BallDropWidgetState extends State<BallDropWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final geolocationController = Get.find<GeolocationController>();
  late int ballCount;
  final List<BallPhysics> _balls = [];
  final double ballRadius = 30.0;
  double screenWidth = 0.0;
  double screenHeight = 0.0;
  double bottomLimit = 0.0;
  double topLimit = 0.0;

  StreamSubscription? _accelerometerSubscription;

  // 기울기 데이터 저장
  double gravityX = 0.0;
  double gravityY = 1.0;

  // 방위각 데이터 저장
  double deviceHeading = 0.0;

  // GPS 및 방향 데이터
  Position? get currentPosition => geolocationController.currentPosition.value;

  @override
  void initState() {
    super.initState();
    ballCount = widget.capsules.length;

    _initializeBalls(widget.capsules);

    // 가속도 센서 구독
    _listenToAccelerometer();

    _listenToLocationStream();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(() {
      if (!mounted) return;
      setState(() {
        const deltaTime = 1 / 24;
        for (final ball in _balls) {
          ball.update(deltaTime, screenWidth, bottomLimit, topLimit, -gravityX,
              gravityY);
        }

        for (int i = 0; i < _balls.length; i++) {
          for (int j = i + 1; j < _balls.length; j++) {
            _balls[i].handleCollision(_balls[j]);
          }
        }
      });
    });
  }

  void _listenToLocationStream() {
    geolocationController.positionStream.value = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3, // 최소 거리 필터
      ),
    ).listen((position) {
      if (!mounted) return;
      final userOffset = Offset(position.longitude, position.latitude);
      for (final ball in _balls) {
        ball.updateUserPosition(userOffset);
      }
      setState(() {});
    });
  }

  void _listenToAccelerometer() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (!mounted) return;
      setState(() {
        gravityX = event.x / 10; // 민감도 조절
        gravityY = event.y / 10; // 민감도 조절
      });
    });
  }

  void _initializeBalls(capsules) {
    _balls.clear();
    for (final capsule in capsules) {
      if (capsule == null) continue;
      _addNewBall(capsule);
    }
  }

  void _addNewBall(capsule) {
    final randomOffsetX = (Random().nextDouble() - 0.5) * 50;
    final randomOffsetY = Random().nextDouble() * 50 + 100;

    final newBall = BallPhysics(
      id: capsule['id'],
      title: capsule['title'],
      content: capsule['content'],
      imageUrl: capsule['imageUrl'] ?? '',
      radius: ballRadius,
      isUnlocked: capsule['unlockedAt'] != null,
      userPosition: Offset(
        currentPosition?.longitude ?? 0,
        currentPosition?.latitude ?? 0,
      ),
      position: Offset(
        Random().nextDouble() * screenWidth,
        Random().nextDouble() * 100,
      ),
      velocity: Offset(randomOffsetX, randomOffsetY),
      date: (capsule['canUnlockedAt'] as Timestamp).toDate(),
      gpsCoordinates: Offset(
        capsule['location'].longitude,
        capsule['location'].latitude,
      ),
    );

    _balls.add(newBall);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    const navBarHeight = kBottomNavigationBarHeight;
    bottomLimit = screenHeight - navBarHeight - 150;
    topLimit = 0;
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    _accelerometerSubscription?.cancel();
    geolocationController.positionStream.value?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        final touchPoint = details.localPosition;
        for (final ball in _balls) {
          if ((touchPoint - ball.position).distance <= ballRadius) {
            _showBallDetails(ball);
            break;
          }
        }
        setState(() {
          _scatterBalls(touchPoint);
        });
      },
      child: CustomPaint(
        painter: BallPainter(_balls),
        child: Container(),
      ),
    );
  }

  void _scatterBalls(Offset touchPoint) {
    for (final ball in _balls) {
      final direction = (ball.position - touchPoint).normalize();
      final randomSpeed = Random().nextDouble() * 300 + 100;
      final newVelocity = direction * randomSpeed;

      ball.velocity = newVelocity;
    }
  }

  void _showBallDetails(BallPhysics ball) {
    final RxString locationMessage = ''.obs; // RxString 생성

    // 초기 메시지 설정
    if (currentPosition != null) {
      locationMessage.value = calculateLocationDifference(ball.gpsCoordinates);
    } else {
      locationMessage.value = '위치 정보를 가져오는 중...';
    }

    // 방위각과 위치 데이터 변경 시 메시지 업데이트
    final compassSubscription = FlutterCompass.events!.listen((event) {
      deviceHeading = event.heading ?? 0;
      if (currentPosition != null) {
        locationMessage.value =
            calculateLocationDifference(ball.gpsCoordinates);
      }
    });

    final locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
      ),
    ).listen((position) {
      locationMessage.value =
          calculateLocationDifference(ball.gpsCoordinates, position);
    });

    // 다이얼로그 표시
    showDialog(
      context: context,
      builder: (context) {
        return Obx(() {
          return CapsuleDetailsDialog(
            title: ball.title,
            content: ball.isUnlocked ? ball.content : null,
            imageUrl: ball.isUnlocked ? ball.imageUrl : null,
            date: ball.date,
            locationMessage: locationMessage, // 명확한 .value 참조
            locationString: locationMessage.value,
            isUnlocked: ball.isUnlocked,
            isUnlockable: !ball.isUnlocked &&
                ball.date.isBefore(DateTime.now()) &&
                locationMessage.value.contains('기억 캡슐이 근처에 있습니다.'),
            onUnlock: () async {
              try {
                await FirestoreService.updateCapsuleStatus(
                  capsuleId: ball.id,
                  unlockedAt: DateTime.now(),
                );
                _initializeBalls(await widget.loadCapsules(ball.id));
              } catch (e) {
                showError('기억 캡슐을 열 수 없습니다.');
              }
            },
          );
        });
      },
    ).then((_) {
      // 다이얼로그 닫힌 후 구독 해제
      compassSubscription.cancel();
      locationSubscription.cancel();
    });
  }

  String calculateLocationDifference(Offset ballCoordinates,
      [Position? position]) {
    late Position userPosition;

    if (position != null) {
      userPosition = position;
    } else if (currentPosition != null) {
      userPosition = currentPosition!;
    } else {
      return '위치 정보를 가져오는 중...';
    }

    final distance = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      ballCoordinates.dy,
      ballCoordinates.dx,
    );

    if (distance <= 5) {
      return '기억 캡슐이 근처에 있습니다.';
    }

    // 방위각 계산
    final bearing = Geolocator.bearingBetween(
      userPosition.latitude,
      userPosition.longitude,
      ballCoordinates.dy,
      ballCoordinates.dx,
    );

    // 상대 방향 계산
    final relativeBearing = (bearing - deviceHeading + 360) % 360;

    // 상대 방향을 "앞으로", "뒤로", "왼쪽으로", "오른쪽으로"로 매핑
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

    // 거리 형식화
    final formattedDistance = distance <= 100
        ? '${distance.floor()}m'
        : '${(distance / 1000).toStringAsFixed(1)}km';

    return '$formattedDistance $direction';
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("오류"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }
}
