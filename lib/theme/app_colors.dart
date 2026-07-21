import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFF9F6EF7);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color indigo = Color(0xFF4F46E5);

  // Backgrounds
  static const Color lavender = Color(0xFFF3EFFC);
  static const Color scaffoldBg = Color(0xFFF8F7FC);
  static const Color white = Color(0xFFFFFFFF);

  // Accent
  static const Color green = Color(0xFF22C55E);
  static const Color greenLight = Color(0xFFDCFCE7);
  static const Color red = Color(0xFFEF4444);
  static const Color redLight = Color(0xFFFEE2E2);

  // Card tints
  static const Color pink = Color(0xFFFCE7F3);
  static const Color pinkIcon = Color(0xFFEC4899);
  static const Color mint = Color(0xFFD1FAE5);
  static const Color mintIcon = Color(0xFF10B981);
  static const Color lavenderCard = Color(0xFFEDE9FE);

  // Text
  static const Color textDark = Color(0xFF1F2937);
  static const Color textMedium = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);

  // Borders & Dividers
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, indigo],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    colors: [primary, indigo],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
