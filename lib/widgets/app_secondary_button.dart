import 'package:material_ui/material_ui.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Secondary button styled with soft mint green tint (#E5F5EF) and teal text (#168B83).
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isFullWidth;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final fgColor = isDark ? AppColors.darkOnSecondary : AppColors.lightOnSecondary;

    final buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppSpacing.iconSm, color: fgColor),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: onPressed == null
                ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                : fgColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: AppSpacing.minTouchTarget,
        minWidth: isFullWidth ? double.infinity : AppSpacing.minTouchTarget,
      ),
      child: Material(
        color: onPressed == null ? Colors.transparent : bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          side: BorderSide(
            color: onPressed == null
                ? theme.dividerColor
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: buttonContent,
          ),
        ),
      ),
    );
  }
}
