import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Updated for better contrast
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color accent = Color(0xFF03A9F4);
  static const Color error = Color(0xFFD32F2F);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F5F5);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF000000);
  static const Color onBackground = Color(0xFF000000);

  // Improved text colors for better readability
  static const Color text = Color(0xFF1A1A1A); // Darker for better contrast
  static const Color textSecondary = Color(0xFF666666); // Better contrast than previous grey
  static const Color textLight = Color(0xFF888888); // For subtle text
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White text on primary color

  // Status colors - Enhanced for better visibility
  static const Color connected = Color(0xFF1976D2); // Blue
  static const Color compiling = Color(0xFFFF8F00); // Orange - more vibrant
  static const Color flashing = Color(0xFF7B1FA2); // Purple - deeper
  static const Color done = Color(0xFF388E3C); // Green - deeper
  static const Color success = Color(0xFF388E3C); // Consistent green
  static const Color warning = Color(0xFFFFB300); // Yellow-orange for better visibility
  static const Color info = Color(0xFF1976D2); // Blue

  // Additional UI colors - Updated for better contrast
  static const Color idle = Color(0xFF757575); // Grey
  static const Color cardBackground = Colors.white;
  static const Color shadowColor = Color(0x1F000000); // 12% black
  static const Color dividerColor = Color(0xFFE0E0E0); // Lighter divider
  static const Color buttonPressed = Color(0xFF1565C0); // Darker blue for pressed state
  static const Color buttonDisabled = Color(0xFFBDBDBD);
  static const Color buttonHover = Color(0xFF90CAF9); // Lighter blue for hover state
  static const Color findFile = Color(0xFF1976D2); // Consistent with primary
  static const Color selectVersion = Color(0xFF388E3C); // Green
  static const Color refresh = Color(0xFFFF8F00); // Orange
  static const Color scanQr = Color(0xFF7B1FA2); // Purple

  // Dark theme colors - Better contrast for dark mode
  static const Color darkBackground = Color(0xFF121212); // Material dark background
  static const Color darkSurface = Color(0xFF1E1E1E); // Dark surface color
  static const Color darkCardBackground = Color(0xFF2D2D2D); // Slightly lighter than surface
  static const Color darkDivider = Color(0xFF404040); // Lighter divider for dark theme
  static const Color darkHeaderBackground = Color(0xFF1976D2); // Consistent blue
  static const Color darkTabBackground = Color(0xFF333333);
  static const Color darkPanelBackground = Color(0xFF252525);
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // Pure white for primary text
  static const Color darkTextSecondary = Color(0xFFB3B3B3); // Light grey for secondary text
  static const Color darkTextLight = Color(0xFF999999); // Subtle text in dark mode

  // Icon colors for better visibility
  static const Color iconPrimary = Color(0xFF1976D2);
  static const Color iconSecondary = Color(0xFF666666);
  static const Color iconLight = Color(0xFF999999);
  static const Color iconSuccess = Color(0xFF388E3C);
  static const Color iconWarning = Color(0xFFFFB300);
  static const Color iconError = Color(0xFFD32F2F);
  static const Color iconInfo = Color(0xFF1976D2);

  // Dark theme icon colors
  static const Color darkIconPrimary = Color(0xFF90CAF9);
  static const Color darkIconSecondary = Color(0xFFB3B3B3);
  static const Color darkIconLight = Color(0xFF808080);
}
