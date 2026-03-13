import 'package:flutter/material.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/theme/text_styles.dart';
import 'package:saferide/core/theme/widget_themes.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          error: AppColors.danger,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: AppTextStyles.textTheme,
        appBarTheme: WidgetThemes.appBarTheme,
        elevatedButtonTheme: WidgetThemes.elevatedButtonTheme,
        outlinedButtonTheme: WidgetThemes.outlinedButtonTheme,
        textButtonTheme: WidgetThemes.textButtonTheme,
        inputDecorationTheme: WidgetThemes.inputDecorationTheme,
        cardTheme: WidgetThemes.cardTheme,
        bottomNavigationBarTheme:
            WidgetThemes.bottomNavigationBarTheme,
        floatingActionButtonTheme:
            WidgetThemes.floatingActionButtonTheme,
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primaryLight,
          error: AppColors.danger,
          surface: AppColors.surfaceDark,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        textTheme: AppTextStyles.textTheme,
        appBarTheme: WidgetThemes.appBarThemeDark,
        elevatedButtonTheme: WidgetThemes.elevatedButtonTheme,
        outlinedButtonTheme: WidgetThemes.outlinedButtonTheme,
        textButtonTheme: WidgetThemes.textButtonTheme,
        inputDecorationTheme:
            WidgetThemes.inputDecorationThemeDark,
        cardTheme: WidgetThemes.cardThemeDark,
      );
}
