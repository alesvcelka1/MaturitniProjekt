import 'package:flutter/material.dart';
import 'light_theme.dart';
import 'dark_theme.dart';

/// Centrální správa motivů aplikace
class AppTheme {
  AppTheme._();

  /// Světlý motiv
  static ThemeData get light => LightTheme.theme;

  /// Tmavý motiv
  static ThemeData get dark => DarkTheme.theme;

  /// Společné konstanty pro oba motivy
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color secondaryPurple = Color(0xFF667EEA);
  
  /// Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  
  /// Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  
  /// Shadows
  static List<BoxShadow> get lightShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get darkShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
}
