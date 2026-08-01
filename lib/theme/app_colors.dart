import 'package:flutter/material.dart';

abstract class AppColorsPalette {
  Color get primary;
  Color get primaryLight;
  Color get primaryDark;
  Color get indigo;
  Color get lavender;
  Color get scaffoldBg;
  Color get background;
  Color get white;
  Color get surface;
  Color get card;
  Color get onPrimary;
  Color get onSurface;
  Color get orange;
  Color get green;
  Color get greenLight;
  Color get red;
  Color get redLight;
  Color get pink;
  Color get pinkIcon;
  Color get mint;
  Color get mintIcon;
  Color get lavenderCard;
  Color get textDark;
  Color get textMedium;
  Color get textLight;
  Color get border;
  Color get divider;
  LinearGradient get primaryGradient;
  LinearGradient get primaryGradientVertical;
}

class AppColorsLight implements AppColorsPalette {
  @override Color get primary => const Color(0xFF7C3AED);
  @override Color get primaryLight => const Color(0xFF9F6EF7);
  @override Color get primaryDark => const Color(0xFF5B21B6);
  @override Color get indigo => const Color(0xFF4F46E5);
  @override Color get lavender => const Color(0xFFF3EFFC);
  @override Color get scaffoldBg => const Color(0xFFF8F7FC);
  @override Color get background => scaffoldBg;
  @override Color get white => const Color(0xFFFFFFFF);
  @override Color get surface => const Color(0xFFFFFFFF);
  @override Color get card => const Color(0xFFFFFFFF);
  @override Color get onPrimary => const Color(0xFFFFFFFF);
  @override Color get onSurface => const Color(0xFF1F2937);
  @override Color get orange => const Color(0xFFF97316);
  @override Color get green => const Color(0xFF22C55E);
  @override Color get greenLight => const Color(0xFFDCFCE7);
  @override Color get red => const Color(0xFFEF4444);
  @override Color get redLight => const Color(0xFFFEE2E2);
  @override Color get pink => const Color(0xFFFCE7F3);
  @override Color get pinkIcon => const Color(0xFFEC4899);
  @override Color get mint => const Color(0xFFD1FAE5);
  @override Color get mintIcon => const Color(0xFF10B981);
  @override Color get lavenderCard => const Color(0xFFEDE9FE);
  @override Color get textDark => const Color(0xFF1F2937);
  @override Color get textMedium => const Color(0xFF6B7280);
  @override Color get textLight => const Color(0xFF9CA3AF);
  @override Color get border => const Color(0xFFE5E7EB);
  @override Color get divider => const Color(0xFFF3F4F6);
  @override LinearGradient get primaryGradient => const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
  @override LinearGradient get primaryGradientVertical => const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}

class AppColorsDark implements AppColorsPalette {
  @override Color get primary => const Color(0xFF7C3AED);
  @override Color get primaryLight => const Color(0xFF9F6EF7);
  @override Color get primaryDark => const Color(0xFF5B21B6);
  @override Color get indigo => const Color(0xFF4F46E5);
  @override Color get lavender => const Color(0xFF1A1A24); // Darker container
  @override Color get scaffoldBg => const Color(0xFF0F0F14); // Very dark scaffold
  @override Color get background => scaffoldBg;
  @override Color get white => const Color(0xFFFFFFFF); // Literal white
  @override Color get surface => const Color(0xFF1A1A24);
  @override Color get card => const Color(0xFF1A1A24); // Maps white cards to dark gray
  @override Color get onPrimary => const Color(0xFFFFFFFF);
  @override Color get onSurface => const Color(0xFFF3F4F6);
  @override Color get orange => const Color(0xFFF97316);
  @override Color get green => const Color(0xFF22C55E);
  @override Color get greenLight => const Color(0xFF14532D); 
  @override Color get red => const Color(0xFFEF4444);
  @override Color get redLight => const Color(0xFF7F1D1D); 
  @override Color get pink => const Color(0xFF501831); 
  @override Color get pinkIcon => const Color(0xFFF472B6);
  @override Color get mint => const Color(0xFF064E3B); 
  @override Color get mintIcon => const Color(0xFF34D399);
  @override Color get lavenderCard => const Color(0xFF2E2442); 
  @override Color get textDark => const Color(0xFFF3F4F6); // Inverse: Light text
  @override Color get textMedium => const Color(0xFF9CA3AF);
  @override Color get textLight => const Color(0xFF6B7280);
  @override Color get border => const Color(0xFF374151); 
  @override Color get divider => const Color(0xFF1F2937); 
  @override LinearGradient get primaryGradient => const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
  @override LinearGradient get primaryGradientVertical => const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}

extension AppColorsExt on BuildContext {
  AppColorsPalette get colors => Theme.of(this).brightness == Brightness.dark ? AppColorsDark() : AppColorsLight();
}
