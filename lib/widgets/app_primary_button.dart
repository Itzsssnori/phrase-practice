import 'package:material_ui/material_ui.dart';
import '../theme/app_spacing.dart';

/// Primary action button following the 16px corner radius and 48px touch target.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: AppSpacing.iconSm,
            height: AppSpacing.iconSm,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ] else if (icon != null) ...[
          Icon(icon, size: AppSpacing.iconSm),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: onPressed == null
                ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                : theme.colorScheme.onPrimary,
          ),
        ),
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: AppSpacing.minTouchTarget,
        minWidth: isFullWidth ? double.infinity : AppSpacing.minTouchTarget,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: buttonContent,
      ),
    );
  }
}
