import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
    geolocationController.startLocationStream();

    geolocationController.positionStream.value = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5, // 최소 거리 필터
      ),
    ).listen((position) {
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
    final canProvideLocation = currentPosition != null;

    late final String? locationDifference;
    late final String locationMessage;
    late final bool isUnlockable;

    if (canProvideLocation) {
      locationDifference = calculateLocationDifference(ball.gpsCoordinates);
      locationMessage = locationDifference ?? '위치 정보를 가져오는 중...';
      isUnlockable = !ball.isUnlocked &&
          ball.date.isBefore(DateTime.now()) &&
          locationDifference != null &&
          locationDifference == '기억 캡슐의 위치입니다.';
    } else {
      locationMessage = '위치 정보 제공 불가';
      isUnlockable = false;
    }

    showDialog(
      context: context,
      builder: (context) {
        return CapsuleDetailsDialog(
            title: ball.title,
            content: ball.content,
            imageUrl: ball.imageUrl,
            date: ball.date,
            locationMessage: locationMessage,
            isUnlocked: ball.isUnlocked,
            isUnlockable: isUnlockable,
            onUnlock: () async {
              try {
                await FirestoreService.updateCapsuleStatus(
                  capsuleId: ball.id,
                  unlockedAt: DateTime.now(),
                );
                _initializeBalls(await widget.loadCapsules());
              } catch (e) {
                _showError("잠금 해제에 실패했습니다.");
              }
            });
      },
    );
  }

  String? calculateLocationDifference(Offset ballCoordinates) {
    if (currentPosition == null) {
      return null;
    }
    final distance = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      ballCoordinates.dy,
      ballCoordinates.dx,
    );

    if (distance <= 25) {
      return '기억 캡슐의 위치입니다.';
    }

    final direction = Geolocator.bearingBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      ballCoordinates.dy,
      ballCoordinates.dx,
    );

    print('Distance: $distance, Direction: $direction');
    return '거리 ${distance.floor()}m 방향: (${direction.floor()}°)';
  }

  void _showError(String message) {
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
