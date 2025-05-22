// lib/core/theme.dart
import 'package:flutter/material.dart';

final appTheme = ThemeData(
  // 🔥 Added: 앱 전체 기본 폰트 패밀리를 GmarketSans로 설정
  fontFamily: 'GmarketSans',

  primaryColor: Colors.green,
  colorScheme: ColorScheme.fromSwatch().copyWith(
    primary: Colors.green,
    secondary: Colors.greenAccent,
  ),

  // 🔥 Added: 기본 텍스트 테마에도 커스텀 폰트 적용
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontFamily: 'GmarketSans'),
    bodyMedium: TextStyle(fontFamily: 'GmarketSans'),
    bodySmall: TextStyle(fontFamily: 'GmarketSans'),
    headlineSmall: TextStyle(fontFamily: 'GmarketSans'),
    titleMedium: TextStyle(fontFamily: 'GmarketSans'),
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
    // 🔥 Added: AppBar 타이틀에 폰트와 굵기 지정
    titleTextStyle: TextStyle(
      fontFamily: 'GmarketSans',
      fontWeight: FontWeight.w500,
      fontSize: 20,
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      // 🔥 Added: 버튼 텍스트에도 커스텀 폰트와 medium weight 적용
      textStyle: const TextStyle(
        fontFamily: 'GmarketSans',
        fontWeight: FontWeight.w500,
      ),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.black,
      // 🔥 Added: TextButton 텍스트에도 커스텀 폰트 적용
      textStyle: const TextStyle(
        fontFamily: 'GmarketSans',
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
);
