import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette
  static const Color primaryLight = Color(0xFFFFF4E0); // 부드러운 노란색
  static const Color primaryDefault = Color(0xFFFFE4A3); // 기본 노란색
  static const Color primaryDark = Color(0xFFFFCC66); // 어두운 노란색

  static const Color secondaryLight = Color(0xFFFDFDFD); // 밝은 화이트
  static const Color secondaryDefault = Color(0xFFF5F5F5); // 기본 회색
  static const Color secondaryDark = Color(0xFFD9D9D9); // 어두운 회색

  static const Color accentPeach = Color(0xFFFFD8C2); // 복숭아색
  static const Color textLight = Color(0xFF333333); // 검정
  static const Color textDefault = Color(0xFF1A1A1A); // 진한 검정
  static const Color textDark = Color(0xFF0D0D0D); // 어두운 검정

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primaryDefault,
      onPrimary: textDefault,
      secondary: accentPeach,
      onSecondary: textLight,
      error: Colors.red,
      onError: Colors.white,
      surface: secondaryDefault,
      onSurfaceVariant: textLight,
      onSurface: textDefault,
    ),
    scaffoldBackgroundColor: secondaryLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryDefault,
      foregroundColor: textDefault,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontSize: 32.0, fontWeight: FontWeight.bold, color: textDefault),
      displayMedium: TextStyle(
          fontSize: 24.0, fontWeight: FontWeight.w600, color: textDefault),
      bodyLarge: TextStyle(
          fontSize: 16.0, fontWeight: FontWeight.normal, color: textDefault),
      bodyMedium: TextStyle(
          fontSize: 14.0, fontWeight: FontWeight.normal, color: textLight),
      bodySmall: TextStyle(
          fontSize: 12.0, fontWeight: FontWeight.normal, color: textDark),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: secondaryLight,
        backgroundColor: primaryDefault,
        textStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
      ),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: primaryDark,
      onPrimary: textLight,
      secondary: accentPeach,
      onSecondary: textDefault,
      error: Colors.red,
      onError: Colors.black,
      surface: secondaryDark,
      onSurfaceVariant: textDefault,
      onSurface: textLight,
    ),
    scaffoldBackgroundColor: textDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryDark,
      foregroundColor: textLight,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontSize: 32.0, fontWeight: FontWeight.bold, color: textLight),
      displayMedium: TextStyle(
          fontSize: 24.0, fontWeight: FontWeight.w600, color: textLight),
      bodyLarge: TextStyle(
          fontSize: 16.0, fontWeight: FontWeight.normal, color: textLight),
      bodyMedium: TextStyle(
          fontSize: 14.0, fontWeight: FontWeight.normal, color: textDefault),
      bodySmall: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.normal,
          color: secondaryDefault),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: textDark,
        backgroundColor: primaryDark,
        textStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
