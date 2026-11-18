import 'package:material_ui/material_ui.dart';
import '../models/language.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Interactive chip displaying a language flag, name, and subtle rounded border.
class LanguageChip extends StatelessWidget {
  final Language language;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool showDropdownIcon;

  const LanguageChip({
    super.key,
    required this.language,
    this.onTap,
    this.isSelected = false,
    this.showDropdownIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isSelected
        ? (isDark ? AppColors.darkSecondary : AppColors.lightSecondary)
        : theme.colorScheme.surface;
    final borderColor = isSelected
        ? theme.colorScheme.primary.withValues(alpha: 0.5)
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final textColor = isSelected
        ? theme.colorScheme.primary
        : (isDark ? AppColors.darkText : AppColors.lightText);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppSpacing.minTouchTarget,
      ),
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          side: BorderSide(color: borderColor, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  language.flag,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  language.name,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (showDropdownIcon) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: AppSpacing.iconSm,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
