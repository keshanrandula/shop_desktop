import 'package:flutter/material.dart';

class AppTheme {
  // Vibrant Material 3 Color Palette (Deep Indigo Space theme)
  static const Color background = Color(0xFF0B0F19);      // Extremely deep space blue
  static const Color surface = Color(0xFF151D30);         // Glossy dark slate/blue surface
  static const Color surfaceSecondary = Color(0xFF1E294B); // Deeper indigo surface
  
  static const Color primary = Color(0xFF6366F1);         // Electric Indigo
  static const Color primaryLight = Color(0xFF818CF8);    // Neon Indigo
  static const Color secondary = Color(0xFF06B6D4);       // Bright Cyan
  static const Color tertiary = Color(0xFFEC4899);        // Hot Pink
  static const Color accent = primary;                    // Indigo Accent Alias
  
  static const Color textPrimary = Color(0xFFF8FAFC);     // Pure off-white
  static const Color textSecondary = Color(0xFF94A3B8);   // Muted slate gray
  static const Color textMuted = Color(0xFF475569);       // Darker slate gray
  
  static const Color border = Color(0xFF22304E);          // Electric blue-gray border
  static const Color borderLight = Color(0xFF2E3F66);     // Highlighted border
  
  // Status Colors
  static const Color success = Color(0xFF10B981);         // Emerald Green
  static const Color warning = Color(0xFFF59E0B);         // Sunset Amber
  static const Color danger = Color(0xFFEF4444);          // Coral Red

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      dividerColor: border,
      
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: surface,
        error: danger,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        outline: border,
      ),

      // Typographical theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.5,
          fontFamily: 'system-ui',
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 0.1,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),

      // Custom Card designs with generous Material 3 curves and borders
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1.2),
        ),
      ),

      // Material 3 Navigation Rail styling
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: IconThemeData(color: primaryLight, size: 24),
        unselectedIconTheme: IconThemeData(color: textSecondary, size: 22),
        selectedLabelTextStyle: TextStyle(
          color: primaryLight,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 11,
        ),
        indicatorColor: Color(0xFF28345C), // Vibrant active indicator bg
        labelType: NavigationRailLabelType.all,
      ),

      // Form Field Decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF0F1424),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 1.2),
        ),
      ),

      // Dialog styling
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1.5),
        ),
      ),

      // Scrollbar style
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(borderLight),
        trackColor: WidgetStateProperty.all(Colors.transparent),
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(5),
      ),

      // Button styles
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
