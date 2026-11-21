import 'package:material_ui/material_ui.dart';
import '../models/language.dart';
import '../theme/app_spacing.dart';

/// Interactive chip displaying a single language flag, name, and subtle rounded border.
class LanguageChip extends StatelessWidget {
  final Language language;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool showDropdownIcon;
  final String? labelOverride;
  final String? semanticsLabel;
  final String? roleLabel; // e.g. "I speak" or "I'm learning"

  const LanguageChip({
    super.key,
    required this.language,
    this.onTap,
    this.isSelected = false,
    this.showDropdownIcon = true,
    this.labelOverride,
    this.semanticsLabel,
    this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor = isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface;
    final borderColor = isSelected ? theme.colorScheme.primary : theme.dividerColor;
    final textColor = isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface;
    final iconColor = isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant;
    final labelText = labelOverride ?? language.name;

    final computedSemantics = semanticsLabel ??
        (roleLabel != null
            ? '$roleLabel: ${language.name}. Tap to change.'
            : 'Selected language: $labelText. Tap to change.');

    return Semantics(
      button: true,
      label: computedSemantics,
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
                  if (roleLabel != null) ...[
                    Text(
                      '$roleLabel: ',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  Text(
                    language.flag,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      labelText,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: textColor,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
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

/// Specialized interactive chip displaying the active language pair (I speak → I'm learning).
///
/// Fully responsive across all screen widths (320px to 1280px) and text scales (up to 2.0x).
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
      label: "I speak ${nativeLanguage.name}. I'm learning ${targetLanguage.name}. Tap to change languages.",
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
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  // Native part: "I speak [flag] [name]"
                  Text(
                    'I speak',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    nativeLanguage.flag,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    nativeLanguage.name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    softWrap: true,
                  ),

                  // Direction arrow
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),

                  // Target part: "I'm learning [flag] [name]"
                  Text(
                    "I'm learning",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    targetLanguage.flag,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    targetLanguage.name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    softWrap: true,
                  ),
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
