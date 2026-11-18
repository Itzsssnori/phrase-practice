import 'package:material_ui/material_ui.dart';

/// Semantic colors for Phrase Practice with a minimalist, approachable palette.
class AppColors {
  AppColors._();

  // --- Light Palette ---
  // Primary: Teal green #168B83
  static const Color lightPrimary = Color(0xFF168B83);
  static const Color lightOnPrimary = Colors.white;

  // Secondary: Soft mint green #E5F5EF
  static const Color lightSecondary = Color(0xFFE5F5EF);
  static const Color lightOnSecondary = Color(0xFF168B83);

  // Background: Off-white #FAFBFA
  static const Color lightBackground = Color(0xFFFAFBFA);

  // Surface: White #FFFFFF
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSubtle = Color(0xFFF4F7F6);

  // Accent: Light blue-green #E9F4F5
  static const Color lightAccent = Color(0xFFE9F4F5);
  static const Color lightOnAccent = Color(0xFF168B83);

  // Primary text: Dark charcoal #202B2A
  static const Color lightText = Color(0xFF202B2A);

  // Secondary text: Muted gray #77817F
  static const Color lightTextSecondary = Color(0xFF77817F);
  static const Color lightTextTertiary = Color(0xFFA5AFA3);

  // Success & Error (Soft tones)
  static const Color lightSuccess = Color(0xFF2E9E68);
  static const Color lightSuccessBackground = Color(0xFFE8F7F0);
  static const Color lightError = Color(0xFFDC4C4C);
  static const Color lightErrorBackground = Color(0xFFFDE8E8);
  static const Color lightWarning = Color(0xFFE59324);

  // Subtle borders & divider
  static const Color lightBorder = Color(0xFFE5ECEB);
  static const Color lightDivider = Color(0xFFF0F4F3);

  // --- Dark Palette (Derived matching with equal contrast) ---
  static const Color darkPrimary = Color(0xFF2CB8AD);
  static const Color darkOnPrimary = Color(0xFF0D3330);

  static const Color darkSecondary = Color(0xFF193835);
  static const Color darkOnSecondary = Color(0xFF9EE0DA);

  static const Color darkBackground = Color(0xFF121B1A);
  static const Color darkSurface = Color(0xFF1A2624);
  static const Color darkSurfaceSubtle = Color(0xFF233230);

  static const Color darkAccent = Color(0xFF213634);
  static const Color darkOnAccent = Color(0xFF86D5CD);

  static const Color darkText = Color(0xFFF2F6F5);
  static const Color darkTextSecondary = Color(0xFF96A4A2);
  static const Color darkTextTertiary = Color(0xFF6B7B79);

  static const Color darkSuccess = Color(0xFF45B980);
  static const Color darkError = Color(0xFFE86666);
  static const Color darkWarning = Color(0xFFF2A33A);

  static const Color darkBorder = Color(0xFF283A37);
  static const Color darkDivider = Color(0xFF22312E);
}
