import 'package:material_ui/material_ui.dart';

/// Semantic colors for Phrase Practice in Light and Dark themes.
class AppColors {
  AppColors._();

  // --- Light Palette ---
  static const Color lightPrimary = Color(0xFF0F766E); // Teal #0F766E
  static const Color lightOnPrimary = Colors.white;
  static const Color lightPrimaryContainer = Color(0xFFCCFBF1);
  static const Color lightOnPrimaryContainer = Color(0xFF115E59);

  static const Color lightAccent = Color(0xFFF59E0B); // Amber #F59E0B
  static const Color lightOnAccent = Color(0xFF451A03);

  static const Color lightBackground = Color(0xFFF8FAFC); // #F8FAFC
  static const Color lightSurface = Colors.white; // cards: white
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);

  static const Color lightText = Color(0xFF0F172A); // Text #0F172A
  static const Color lightTextSecondary = Color(0xFF64748B); // Secondary #64748B
  static const Color lightTextTertiary = Color(0xFF94A3B8);

  static const Color lightSuccess = Color(0xFF16A34A); // Success #16A34A
  static const Color lightError = Color(0xFFDC2626); // Error #DC2626
  static const Color lightWarning = Color(0xFFF59E0B); // Warning #F59E0B

  static const Color lightBorder = Color(0xFFE2E8F0); // Soft neutral border
  static const Color lightDivider = Color(0xFFF1F5F9);

  // --- Dark Palette ---
  // Matching dark version with equal contrast and same teal identity
  static const Color darkPrimary = Color(0xFF2DD4BF); // Vibrant teal for dark background
  static const Color darkOnPrimary = Color(0xFF042F2E);
  static const Color darkPrimaryContainer = Color(0xFF134E4A);
  static const Color darkOnPrimaryContainer = Color(0xFFCCFBF1);

  static const Color darkAccent = Color(0xFFFBBF24); // Amber highlight
  static const Color darkOnAccent = Color(0xFF451A03);

  static const Color darkBackground = Color(0xFF0F172A); // Deep slate
  static const Color darkSurface = Color(0xFF1E293B); // Elevated slate cards
  static const Color darkSurfaceVariant = Color(0xFF334155);

  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);

  static const Color darkSuccess = Color(0xFF22C55E);
  static const Color darkError = Color(0xFFEF4444);
  static const Color darkWarning = Color(0xFFFBBF24);

  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF1E293B);
}
