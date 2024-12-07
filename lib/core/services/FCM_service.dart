import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;

  FCMService._internal();

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    // 알림 권한 요청
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {}

    // 백그라운드 메시지 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 포그라운드 메시지 핸들러 등록
    FirebaseMessaging.onMessage.listen(_firebaseMessagingHandler);
  }

  // 백그라운드 메시지 처리
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {}

  // 포그라운드 메시지 처리
  static void _firebaseMessagingHandler(RemoteMessage message) {}

  // 토큰 가져오기
  Future<String?> getToken() async {
    return await FirebaseMessaging.instance.getToken();
  }
}
