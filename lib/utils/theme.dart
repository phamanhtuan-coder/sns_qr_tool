import 'package:flutter/material.dart';

final lightTheme = ThemeData(
  primaryColor: const Color(0xFF2563EB),
  scaffoldBackgroundColor: const Color(0xFFF9FAFB),
  cardColor: Colors.white,
  textTheme: const TextTheme(
    headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF374151)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2563EB),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
);

final darkTheme = ThemeData(
  primaryColor: const Color(0xFF1E40AF),
  scaffoldBackgroundColor: const Color(0xFF111827),
  cardColor: const Color(0xFF1F2A44),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
    bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFD1D5DB)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1E40AF),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
);