import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/route_manager.dart';
import 'package:timea/core/screens/root_scaffold.dart';
import 'package:timea/core/utils/root_scaffold_binding.dart';
import 'package:timea/core/utils/theme.dart';
import 'package:timea/common/screens/splash.dart';
import 'package:timea/features/auth/presentation/login_screen.dart';
import 'package:timea/features/notification/presentation/notification_screen.dart';
import 'package:timea/features/profile/presentation/profile_setup_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Geolocator.requestPermission();
  await _initializeFCM();
  runApp(const MainApp());
}

Future<void> _initializeFCM() async {
  final messaging = FirebaseMessaging.instance;

  // 알림 권한 요청
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print('알림 권한 상태: ${settings.authorizationStatus}');

  // FCM 토큰 출력
  String? token = await messaging.getToken();
  print('FCM 등록 토큰: $token');

  // FCM 백그라운드 메시지 핸들러
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

// 백그라운드 메시지 처리
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('백그라운드 메시지: ${message.messageId}');
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Time&',
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      initialRoute: '/splash',
      initialBinding: RootScaffoldBinding(),
      getPages: [
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/', page: () => const RootScaffold()),
        GetPage(name: '/notification', page: () => const NotificationScreen()),
        GetPage(name: '/profileSetup', page: () => const ProfileSetupScreen()),
      ],
    );
  }
}
