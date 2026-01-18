import 'package:flutter/material.dart';

/// App color palette
abstract class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF2C2C2C);           // Main primary - dark grey
  static const Color primaryLight = Color(0xFFBBBBBB);      // Light primary for indicators
  static const Color primaryDark = Color(0xFF1A1A1A);       // Darker variant

  // Secondary/Accent colors
  static const Color secondary = Color(0xFFFF8205);         // Deep orange
  static const Color secondaryLight = Color(0xFFFF9933);    // Light orange
  static const Color secondaryDark = Color(0xFFE67300);     // Darker orange

  // Neutral colors
  static const Color background = Color(0xFFF3F3F3);        // Grey background
  static const Color surface = Color(0xFFFFFFFF);           // White surface
  static const Color surfaceVariant = Color(0xFFF5F6F8);    // Grey button/card background
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);

  // Text colors
  static const Color textPrimary = Color(0xFF333333);       // Main text color
  static const Color textSecondary = Color(0xFF606060);     // Subtitle/secondary text
  static const Color textTertiary = Color(0xFF595959);      // Label text
  static const Color textDisabled = Color(0xFFA4A4A4);      // Disabled/inactive text
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Icon colors
  static const Color iconSecondary = Color(0xFF8D8C95);     // Info/secondary icons

  // Border colors
  static const Color border = Color(0xFFE8E8E8);            // Default border color

  // Link colors
  static const Color link = Color(0xFF0D69D4);              // Hyperlink blue

  // Button colors
  static const Color buttonPrimary = Color(0xFF2C2C2C);     // Primary button
  static const Color buttonSecondary = Color(0xFFF5F6F8);   // Secondary/grey button
  static const Color buttonInactive = Color(0xFF4A4A4A);    // Inactive button
}

/// App text styles
abstract class AppTextStyles {
  static const String fontFamily = 'Manrope';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
}

/// App theme configuration
abstract class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTextStyles.fontFamily,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryLight,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnPrimary,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textOnPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(43),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(43),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.textHint),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.textHint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    // TODO: Implement dark theme when needed
    return lightTheme;
  }
}
