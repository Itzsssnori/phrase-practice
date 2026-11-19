import 'package:material_ui/material_ui.dart';
import '../models/category.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_settings_scope.dart';

/// Minimalist, rounded category card showcasing topic details and learning progress
/// with 0.98 scale press animation and earthy icon tints.
class CategoryCard extends StatefulWidget {
  final Category category;
  final VoidCallback? onTap;
  final int? colorIndex;
  final int? learnedCount;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.colorIndex,
    this.learnedCount,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tintIndex = widget.colorIndex ?? AppColors.categoryIdToIndex(widget.category.id);
    final tint = AppColors.getCategoryTint(tintIndex, isDark);

    // Read native language dynamically from settings scope so card title updates immediately
    final settings = AppSettingsScope.maybeOf(context);
    final nativeCode = settings?.nativeLanguageCode ?? 'en';
    final categoryTitle = widget.category.nameFor(nativeCode);

    final progressText = widget.learnedCount != null
        ? '${widget.learnedCount} of ${widget.category.phraseCount} learned'
        : '${widget.category.phraseCount} phrases';

    return Semantics(
      button: true,
      label: '$categoryTitle category, $progressText',
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: theme.dividerColor,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (highlighted) {
                setState(() => _isPressed = highlighted);
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Responsive icon and count header (Wrap prevents overflow on narrow widths/large text)
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: tint.background,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                          ),
                          child: Icon(
                            widget.category.icon,
                            color: tint.foreground,
                            size: AppSpacing.iconMd,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                          ),
                          child: Text(
                            progressText,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Category Title in native language
                    Text(
                      categoryTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        height: 1.3,
                      ),
                      softWrap: true,
                    ),

                    if (widget.category.description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.category.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
