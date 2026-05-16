import 'package:flutter/material.dart';
import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';

/// Builds the light and dark [ThemeData] for the Fitness Care Bagerhat app.
///
/// Both themes share the same typography scale and brand colors,
/// with surfaces and backgrounds adjusted for legibility.
///
/// See also:
/// - [AppColors] for the brand palette
/// - [AppText] for the typography scale
abstract final class AppTheme {
  /// Light theme — default for daytime use.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.bgLight,
        canvasColor: AppColors.bgLight,
        cardColor: AppColors.surfaceLight,
        dividerColor: const Color(0xFFE5E7EB),
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.bgLight,
          foregroundColor: AppColors.textPrimary,
          centerTitle: false,
          titleTextStyle: AppText.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        textTheme: _textTheme(Brightness.light),
        inputDecorationTheme: _inputDecorationTheme(Brightness.light),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppText.labelLarge,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppText.labelLarge,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppText.labelLarge,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.primary.withValues(alpha: 0.08),
          selectedColor: AppColors.primary,
          labelStyle: AppText.labelSmall,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          side: BorderSide.none,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceLight,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          showDragHandle: true,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: CircleBorder(),
        ),
      );

  /// Dark theme — for nighttime / battery-saving use.
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.bgDark,
        canvasColor: AppColors.bgDark,
        cardColor: AppColors.surfaceDark,
        dividerColor: const Color(0xFF2D3B2F),
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.bgDark,
          foregroundColor: AppColors.textOnDark,
          centerTitle: false,
          titleTextStyle: AppText.titleLarge.copyWith(
            color: AppColors.textOnDark,
          ),
        ),
        textTheme: _textTheme(Brightness.dark),
        inputDecorationTheme: _inputDecorationTheme(Brightness.dark),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppText.labelLarge,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            side: const BorderSide(color: AppColors.primaryLight),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppText.labelLarge,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            textStyle: AppText.labelLarge,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
          selectedColor: AppColors.primaryLight,
          labelStyle: AppText.labelSmall,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          side: BorderSide.none,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.textHint,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          showDragHandle: true,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: CircleBorder(),
        ),
      );

  static TextTheme _textTheme(Brightness brightness) {
    final color = brightness == Brightness.light
        ? AppColors.textPrimary
        : AppColors.textOnDark;
    final secondaryColor = AppColors.textSecondary;

    return TextTheme(
      displayLarge: AppText.displayLarge.copyWith(color: color),
      displayMedium: AppText.displayMedium.copyWith(color: color),
      headlineLarge: AppText.headlineLarge.copyWith(color: color),
      headlineMedium: AppText.headlineMedium.copyWith(color: color),
      titleLarge: AppText.titleLarge.copyWith(color: color),
      titleMedium: AppText.titleMedium.copyWith(color: color),
      bodyLarge: AppText.bodyLarge.copyWith(color: color),
      bodyMedium: AppText.bodyMedium.copyWith(color: secondaryColor),
      labelLarge: AppText.labelLarge.copyWith(color: color),
      labelSmall: AppText.labelSmall.copyWith(color: secondaryColor),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final fillColor = isLight
        ? const Color(0xFFF3F4F6)
        : AppColors.surfaceDark;
    final borderColor = isLight
        ? const Color(0xFFD1D5DB)
        : const Color(0xFF374151);

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: AppText.bodyMedium.copyWith(color: AppColors.textHint),
      labelStyle: AppText.bodyMedium.copyWith(color: AppColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }
}
