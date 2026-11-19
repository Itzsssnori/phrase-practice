import 'package:material_ui/material_ui.dart';
import '../models/language.dart';
import '../theme/app_spacing.dart';

/// Interactive chip displaying a language flag, name, and subtle rounded border.
class LanguageChip extends StatelessWidget {
  final Language language;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool showDropdownIcon;
  final String? labelOverride;
  final String? semanticsLabel;

  const LanguageChip({
    super.key,
    required this.language,
    this.onTap,
    this.isSelected = false,
    this.showDropdownIcon = true,
    this.labelOverride,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor = isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface;
    final borderColor = isSelected ? theme.colorScheme.primary : theme.dividerColor;
    final textColor = isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface;
    final iconColor = isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant;
    final labelText = labelOverride ?? language.name;

    return Semantics(
      button: true,
      label: semanticsLabel ?? 'Selected language: $labelText. Tap to change.',
      child: ConstrainedBox(
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
                    labelText,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: textColor,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (showDropdownIcon) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.keyboard_arrow_down_outlined,
                      size: AppSpacing.iconSm,
                      color: iconColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Specialized interactive chip displaying the active language pair (Native → Target).
class LanguagePairChip extends StatelessWidget {
  final Language nativeLanguage;
  final Language targetLanguage;
  final VoidCallback? onTap;

  const LanguagePairChip({
    super.key,
    required this.nativeLanguage,
    required this.targetLanguage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Studying ${targetLanguage.name} from ${nativeLanguage.name}. Tap to change language pair.',
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.minTouchTarget,
        ),
        child: Material(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            side: BorderSide(color: theme.dividerColor, width: 1),
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
                    nativeLanguage.flag,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    nativeLanguage.code.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    targetLanguage.flag,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    targetLanguage.name,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.keyboard_arrow_down_outlined,
                    size: AppSpacing.iconSm,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
