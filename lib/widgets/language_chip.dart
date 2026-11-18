import 'package:material_ui/material_ui.dart';
import '../models/language.dart';
import '../theme/app_spacing.dart';

/// Interactive chip displaying a language flag, name, and optional picker trigger.
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

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppSpacing.minTouchTarget,
      ),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          side: BorderSide(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor,
          ),
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
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
                if (showDropdownIcon) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: AppSpacing.iconSm,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
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
