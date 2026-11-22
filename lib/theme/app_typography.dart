import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'app_colors.dart';

/// Clean typography hierarchy using Inter for modern readability.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';

  static TextTheme createTextTheme({required bool isDark}) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final base = GoogleFonts.interTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    ).apply(
      bodyColor: textColor,
      displayColor: textColor,
    );

    return base.copyWith(
      // Top screen heading
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 24.0,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.4,
        height: 1.25,
      ),

      // Section title
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 19.0,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: -0.2,
        height: 1.3,
      ),

      // Card title / original phrase
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 17.0,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: -0.1,
        height: 1.35,
      ),

      // Primary study translation (clear focus, readable on 393px viewport)
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 26.0,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.5,
        height: 1.3,
      ),

      // Default input text (TextField / TextFormField)
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: -0.1,
        height: 1.45,
      ),

      // Standard body
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 15.0,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: -0.1,
        height: 1.45,
      ),

      // Subtitle / secondary explanation
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 13.0,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        letterSpacing: 0,
        height: 1.4,
      ),

      // Category / stat label
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        letterSpacing: 0.1,
      ),

      // Button label
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 15.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    );
  }
}
