import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF6C3EC1);
  static const primaryLight = Color(0xFF9B6FE8);
  static const primaryDark = Color(0xFF4A2590);

  // Status
  static const danger = Color(0xFFFF6B6B);
  static const dangerDark = Color(0xFFD32F2F);
  static const safe = Color(0xFF4CAF50);
  static const safeDark = Color(0xFF2E7D32);
  static const warning = Color(0xFFFFA726);
  static const warningDark = Color(0xFFF57C00);

  // Surfaces
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF121212);
  static const backgroundDark = Color(0xFF1E1E1E);

  // Text
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textOnPrimary = Color(0xFFFFFFFF);
  static const textOnDanger = Color(0xFFFFFFFF);

  // Misc
  static const divider = Color(0xFFE0E0E0);
  static const disabled = Color(0xFFBDBDBD);
  static const shimmerBase = Color(0xFFE0E0E0);
  static const shimmerHighlight = Color(0xFFF5F5F5);

  // Map route colors
  static const routeExpected = Color(0xFF2196F3);
  static const routeActual = Color(0xFF4CAF50);
  static const routeDeviated = Color(0xFFFF6B6B);
}
