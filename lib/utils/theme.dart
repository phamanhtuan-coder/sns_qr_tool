import 'package:flutter/material.dart';
import 'package:smart_net_qr_scanner/utils/app_colors.dart';

final lightTheme = ThemeData(
  useMaterial3: true,
  primaryColor: AppColors.primary,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.accent,
    background: AppColors.background,
    surface: AppColors.cardBackground,
    error: AppColors.error,
  ),
  scaffoldBackgroundColor: AppColors.background,
  cardColor: AppColors.cardBackground,
  shadowColor: AppColors.shadowColor,
  dividerColor: AppColors.dividerColor,
  textTheme: const TextTheme(
    headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
    bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.dividerColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.primary, width: 2.0),
    ),
    fillColor: Colors.white,
    filled: true,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  primaryColor: AppColors.primary,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.accent,
    background: AppColors.darkBackground,
    surface: AppColors.darkCardBackground,
    error: AppColors.error,
  ),
  scaffoldBackgroundColor: AppColors.darkBackground,
  cardColor: AppColors.darkCardBackground,
  shadowColor: AppColors.shadowColor,
  dividerColor: AppColors.darkDivider,
  textTheme: const TextTheme(
    headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary),
    bodyMedium: TextStyle(fontSize: 14, color: AppColors.darkTextSecondary),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.darkDivider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
    ),
    fillColor: AppColors.darkSurface,
    filled: true,
    labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
    hintStyle: TextStyle(color: AppColors.darkTextSecondary.withOpacity(0.7)),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkHeaderBackground,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  iconTheme: const IconThemeData(
    color: AppColors.darkTextPrimary,
  ),
);

