import 'package:flutter/material.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';

abstract final class WidgetThemes {
  // AppBar
  static const appBarTheme = AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    centerTitle: true,
  );

  static const appBarThemeDark = AppBarTheme(
    backgroundColor: AppColors.surfaceDark,
    foregroundColor: AppColors.textOnPrimary,
    elevation: 0,
    centerTitle: true,
  );

  // Elevated Button
  static final elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(AppDimensions.radiusLG),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // Outlined Button
  static final outlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      minimumSize: const Size(double.infinity, 52),
      side: const BorderSide(color: AppColors.primary),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(AppDimensions.radiusLG),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // Text Button
  static final textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // Input Decoration
  static final inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppDimensions.paddingMD,
      vertical: AppDimensions.paddingMD,
    ),
    border: OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(AppDimensions.radiusMD),
      borderSide: const BorderSide(color: AppColors.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(AppDimensions.radiusMD),
      borderSide: const BorderSide(color: AppColors.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(AppDimensions.radiusMD),
      borderSide: const BorderSide(
        color: AppColors.primary,
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(AppDimensions.radiusMD),
      borderSide: const BorderSide(color: AppColors.danger),
    ),
  );

  static final inputDecorationThemeDark =
      inputDecorationTheme.copyWith(
    fillColor: AppColors.surfaceDark,
  );

  // Card
  static final cardTheme = CardTheme(
    color: AppColors.surface,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius:
          BorderRadius.circular(AppDimensions.radiusMD),
    ),
    margin: const EdgeInsets.symmetric(
      vertical: AppDimensions.paddingSM,
    ),
  );

  static final cardThemeDark = CardTheme(
    color: AppColors.surfaceDark,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius:
          BorderRadius.circular(AppDimensions.radiusMD),
    ),
    margin: const EdgeInsets.symmetric(
      vertical: AppDimensions.paddingSM,
    ),
  );

  // Bottom Navigation Bar
  static const bottomNavigationBarTheme =
      BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textSecondary,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  );

  // Floating Action Button
  static const floatingActionButtonTheme =
      FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
  );
}
