import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Semantic typography scale using Noto Sans for cross-language legibility.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Noto Sans';

  static TextTheme createTextTheme({required bool isDark}) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final base = GoogleFonts.notoSansTextTheme();

    return base.copyWith(
      // Screen title (e.g., top app bar or screen hero)
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 26.0,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.5,
        height: 1.25,
      ),

      // Section heading
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: -0.2,
        height: 1.3,
      ),

      // Phrase title / original phrase
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 18.0,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        letterSpacing: 0.1,
        height: 1.4,
      ),

      // Study translation (the largest text on study screens, clear & wrapped)
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 30.0,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.6,
        height: 1.3,
      ),

      // Body text
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 15.0,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0.1,
        height: 1.5,
      ),

      // Secondary body / caption
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 13.0,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        letterSpacing: 0.1,
        height: 1.4,
      ),

      // Label
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 13.0,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        letterSpacing: 0.2,
      ),

      // Button
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 15.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );
  }
}
