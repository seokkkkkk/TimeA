import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/route_manager.dart';
import 'package:timea/core/screens/root_scaffold.dart';
import 'package:timea/core/services/FCM_service.dart';
import 'package:timea/core/services/firebase_auth_service.dart';
import 'package:timea/core/utils/root_scaffold_binding.dart';
import 'package:timea/core/utils/theme.dart';
import 'package:timea/common/screens/splash.dart';
import 'package:timea/features/auth/presentation/login_screen.dart';
import 'package:timea/features/notification/presentation/notification_screen.dart';
import 'package:timea/features/notification/services/notification_service.dart';
import 'package:timea/features/profile/presentation/profile_setup_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Geolocator.requestPermission();
  await FCMService().initialize();
  await NotificationService().initialize();

  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser != null) {
    await FirebaseAuthService().updateFCMToken(currentUser.uid);
  }
  runApp(const MainApp());
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
        GetPage(name: '/notification', page: () => NotificationScreen()),
        GetPage(name: '/profileSetup', page: () => const ProfileSetupScreen()),
      ],
    );
  }
}
