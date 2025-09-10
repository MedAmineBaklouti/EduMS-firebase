import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF19366C), // Your requested blue (#19366C)
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD6E3FF),
    onPrimaryContainer: Color(0xFF001A43),
    secondary: Color(0xFF006874), // Teal for secondary
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF97F0FF),
    onSecondaryContainer: Color(0xFF001F24),
    tertiary: Color(0xFF6D5577), // Purple for tertiary
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF5D8FF),
    onTertiaryContainer: Color(0xFF271431),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: Color(0xFFFDFBFF),
    onBackground: Color(0xFF1A1B1E),
    surface: Color(0xFFFDFBFF),
    onSurface: Color(0xFF1A1B1E),
    surfaceVariant: Color(0xFFE0E2EC),
    onSurfaceVariant: Color(0xFF44474E),
    outline: Color(0xFF74777F),
    shadow: Color(0xFF000000),
    inverseSurface: Color(0xFF2F3033),
    onInverseSurface: Color(0xFFF1F0F4),
    inversePrimary: Color(0xFFA9C7FF),
  );

  // Dark Theme Colors
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFA9C7FF), // Lighter blue for dark mode
    onPrimary: Color(0xFF002E6B),
    primaryContainer: Color(0xFF004299),
    onPrimaryContainer: Color(0xFFD6E3FF),
    secondary: Color(0xFF4FD8EB), // Teal for secondary
    onSecondary: Color(0xFF00363D),
    secondaryContainer: Color(0xFF004F58),
    onSecondaryContainer: Color(0xFF97F0FF),
    tertiary: Color(0xFFD8BDE3), // Purple for tertiary
    onTertiary: Color(0xFF3D2948),
    tertiaryContainer: Color(0xFF553F60),
    onTertiaryContainer: Color(0xFFF5D8FF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    background: Color(0xFF1A1B1E),
    onBackground: Color(0xFFE3E2E6),
    surface: Color(0xFF1A1B1E),
    onSurface: Color(0xFFE3E2E6),
    surfaceVariant: Color(0xFF44474E),
    onSurfaceVariant: Color(0xFFC4C6CF),
    outline: Color(0xFF8E9099),
    shadow: Color(0xFF000000),
    inverseSurface: Color(0xFFE3E2E6),
    onInverseSurface: Color(0xFF2F3033),
    inversePrimary: Color(0xFF19366C), // Your original blue
  );

  // Additional custom colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
  static const Color disabled = Color(0xFF9E9E9E);
}