import 'package:material_ui/material_ui.dart';
import '../theme/app_spacing.dart';

/// Secondary / outlined button with 16px corner radius and 48px touch target.
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
    final buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppSpacing.iconSm),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: onPressed == null
                ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                : theme.colorScheme.primary,
          ),
        ),
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: AppSpacing.minTouchTarget,
        minWidth: isFullWidth ? double.infinity : AppSpacing.minTouchTarget,
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        child: buttonContent,
      ),
    );
  }
}
