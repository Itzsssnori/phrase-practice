import 'package:material_ui/material_ui.dart';

/// Semantic colors for Phrase Practice with a warm, editorial named-token system.
class AppColors {
  AppColors._();

  // --- Light Palette ---
  static const Color lightBackground = Color(0xFFF7F6F2);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFEFEDE6); // Subtle surface
  static const Color lightText = Color(0xFF17201E);
  static const Color lightTextSecondary = Color(0xFF5B6B67);
  static const Color lightTextTertiary = Color(0xFF9BA8A5);
  static const Color lightBorder = Color(0xFFE3E1DA);
  static const Color lightDivider = Color(0xFFE3E1DA);
  static const Color lightPrimary = Color(0xFF0F766E);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFDDEFEB); // Chips, selected states
  static const Color lightOnPrimaryContainer = Color(0xFF0F766E);
  static const Color lightAccent = Color(0xFFF59E0B); // Amber, favorites ONLY
  static const Color lightAccentContainer = Color(0xFFFDF1D6);
  static const Color lightOnAccent = Color(0xFF78350F);
  static const Color lightSuccess = Color(0xFF16A34A);
  static const Color lightSuccessBackground = Color(0xFFF0FDF4);
  static const Color lightError = Color(0xFFDC2626);
  static const Color lightErrorBackground = Color(0xFFFEF2F2);
  static const Color lightWarning = Color(0xFFD97706);

  // --- Dark Palette (tinted charcoal, NOT pure black, NOT inverted) ---
  static const Color darkBackground = Color(0xFF0E1413);
  static const Color darkCard = Color(0xFF162120);
  static const Color darkSurface = Color(0xFF1D2B29); // Elevated surface
  static const Color darkText = Color(0xFFE6ECEA);
  static const Color darkTextSecondary = Color(0xFF9AABA7);
  static const Color darkTextTertiary = Color(0xFF6B7B79);
  static const Color darkBorder = Color(0xFF2A3A37);
  static const Color darkDivider = Color(0xFF2A3A37);
  static const Color darkPrimary = Color(0xFF4FB8AB);
  static const Color darkOnPrimary = Color(0xFF0E1413);
  static const Color darkPrimaryContainer = Color(0xFF17403B);
  static const Color darkOnPrimaryContainer = Color(0xFF9EE0D8);
  static const Color darkAccent = Color(0xFFF2B84B); // Amber
  static const Color darkAccentContainer = Color(0xFF3A2F14);
  static const Color darkOnAccent = Color(0xFFFDE8A0);
  static const Color darkSuccess = Color(0xFF5BBF85);
  static const Color darkSuccessBackground = Color(0xFF0F2A1A);
  static const Color darkError = Color(0xFFE58A8A);
  static const Color darkErrorBackground = Color(0xFF2A1010);
  static const Color darkWarning = Color(0xFFE0A24A);

  // --- Category icon tint pairs (light background, dark background) ---
  static const Color catTealLight = Color(0xFFDDEFEB);
  static const Color catTealDark = Color(0xFF17403B);

  static const Color catAmberLight = Color(0xFFFDF1D6);
  static const Color catAmberDark = Color(0xFF3A2F14);

  static const Color catClayLight = Color(0xFFFAEDE7);
  static const Color catClayDark = Color(0xFF3A1F17);

  static const Color catOliveLight = Color(0xFFEDF3DA);
  static const Color catOliveDark = Color(0xFF1E2D14);

  static const Color catSlateLight = Color(0xFFE6EAF0);
  static const Color catSlateDark = Color(0xFF1A2232);

  // Category tint foreground colors
  static const Color catTealFgLight = Color(0xFF0F766E);
  static const Color catTealFgDark = Color(0xFF9EE0D8);

  static const Color catAmberFgLight = Color(0xFF78350F);
  static const Color catAmberFgDark = Color(0xFFFDE8A0);

  static const Color catClayFgLight = Color(0xFF9C4221);
  static const Color catClayFgDark = Color(0xFFE89E82);

  static const Color catOliveFgLight = Color(0xFF4D6613);
  static const Color catOliveFgDark = Color(0xFFC4DB7D);

  static const Color catSlateFgLight = Color(0xFF2C4364);
  static const Color catSlateFgDark = Color(0xFF9FB7D0);

  // --- Icon color tokens ---
  static const Color lightIconPrimary = Color(0xFF0F766E);
  static const Color lightIconSecondary = Color(0xFF5B6B67);
  static const Color lightIconMuted = Color(0xFF9BA8A5);

  static const Color darkIconPrimary = Color(0xFF4FB8AB);
  static const Color darkIconSecondary = Color(0xFF9AABA7);
  static const Color darkIconMuted = Color(0xFF6B7B79);

  /// Helper to get category tint background and foreground pair by index (0-4).
  static CategoryTint getCategoryTint(int index, bool isDark) {
    final i = (index % 5 + 5) % 5;
    switch (i) {
      case 0:
        return CategoryTint(
          background: isDark ? catTealDark : catTealLight,
          foreground: isDark ? catTealFgDark : catTealFgLight,
        );
      case 1:
        return CategoryTint(
          background: isDark ? catAmberDark : catAmberLight,
          foreground: isDark ? catAmberFgDark : catAmberFgLight,
        );
      case 2:
        return CategoryTint(
          background: isDark ? catClayDark : catClayLight,
          foreground: isDark ? catClayFgDark : catClayFgLight,
        );
      case 3:
        return CategoryTint(
          background: isDark ? catOliveDark : catOliveLight,
          foreground: isDark ? catOliveFgDark : catOliveFgLight,
        );
      case 4:
      default:
        return CategoryTint(
          background: isDark ? catSlateDark : catSlateLight,
          foreground: isDark ? catSlateFgDark : catSlateFgLight,
        );
    }
  }

  /// Helper to resolve category ID into colorIndex (0-4) and return tint.
  static CategoryTint getCategoryTintById(String id, bool isDark) {
    return getCategoryTint(categoryIdToIndex(id), isDark);
  }

  /// Maps standard category IDs to consistent indices (0-4).
  static int categoryIdToIndex(String id) {
    switch (id.toLowerCase()) {
      case 'travel':
        return 0; // Teal
      case 'dining':
        return 1; // Amber
      case 'daily':
        return 2; // Clay
      case 'emergency':
        return 3; // Olive
      case 'shopping':
        return 4; // Slate
      default:
        return id.hashCode.abs() % 5;
    }
  }
}

/// Represents background and foreground tint pair for category indicators.
class CategoryTint {
  final Color background;
  final Color foreground;

  const CategoryTint({
    required this.background,
    required this.foreground,
  });
}

/// Extension on ColorScheme to access theme-wide semantic tokens cleanly.
extension AppColorScheme on ColorScheme {
  Color get accent => brightness == Brightness.dark ? AppColors.darkAccent : AppColors.lightAccent;
  Color get accentContainer =>
      brightness == Brightness.dark ? AppColors.darkAccentContainer : AppColors.lightAccentContainer;
  Color get onAccent => brightness == Brightness.dark ? AppColors.darkOnAccent : AppColors.lightOnAccent;
  Color get success => brightness == Brightness.dark ? AppColors.darkSuccess : AppColors.lightSuccess;
  Color get successBackground =>
      brightness == Brightness.dark ? AppColors.darkSuccessBackground : AppColors.lightSuccessBackground;
  Color get errorBackground =>
      brightness == Brightness.dark ? AppColors.darkErrorBackground : AppColors.lightErrorBackground;
  Color get warning => brightness == Brightness.dark ? AppColors.darkWarning : AppColors.lightWarning;
  Color get surfaceSubtle => brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get textTertiary =>
      brightness == Brightness.dark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
  Color get iconPrimary => brightness == Brightness.dark ? AppColors.darkIconPrimary : AppColors.lightIconPrimary;
  Color get iconSecondary =>
      brightness == Brightness.dark ? AppColors.darkIconSecondary : AppColors.lightIconSecondary;
  Color get iconMuted => brightness == Brightness.dark ? AppColors.darkIconMuted : AppColors.lightIconMuted;
}
