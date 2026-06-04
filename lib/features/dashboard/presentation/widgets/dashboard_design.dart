import 'package:flutter/material.dart';

class DashboardDesign {
  DashboardDesign._();

  static const Color navy = Color(0xFF1A237E);
  static const Color deepNavy = Color(0xFF000666);
  static const Color danger = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);
  static const Color success = Color(0xFF388E3C);
  static const Color info = Color(0xFF0288D1);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFECEFF1);
  static const Color slate = Color(0xFF455A64);

  static const double marginMobile = 16;
  static const double marginTablet = 24;
  static const double gap = 16;
  static const double sectionGap = 24;
  static const double radius = 16;
  static const double compactRadius = 8;
  static const double touchTarget = 48;

  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF101418)
        : lightBackground;
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1B2026)
        : lightSurface;
  }

  static Color surfaceVariant(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF252B33)
        : lightSurfaceVariant;
  }

  static Color mutedText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFC4C7CF)
        : const Color(0xFF49454F);
  }

  static Color outline(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF5F6670)
        : const Color(0xFFC6C5D4);
  }

  static Color primary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFBDC2FF)
        : navy;
  }

  static Color statusBackground(BuildContext context, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Color.alphaBlend(
      color.withValues(alpha: isDark ? 0.28 : 0.12),
      surface(context),
    );
  }

  static List<BoxShadow> cardShadow(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return const [];
    }

    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }
}
