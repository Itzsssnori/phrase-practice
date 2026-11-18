import 'package:material_ui/material_ui.dart';
import '../models/phrase.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_audio_button.dart';
import 'app_favorite_button.dart';

/// Minimalist, approachable phrase card prioritizing legibility and context
/// with 0.98 scale press animation.
class PhraseCard extends StatefulWidget {
  final Phrase phrase;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onFavoriteToggle;

  const PhraseCard({
    super.key,
    required this.phrase,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  State<PhraseCard> createState() => _PhraseCardState();
}

class _PhraseCardState extends State<PhraseCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tint = AppColors.getCategoryTintById(widget.phrase.categoryId, isDark);

    return AnimatedScale(
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
                  // Top Action & Status bar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: tint.background,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                        ),
                        child: Text(
                          widget.phrase.categoryId.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: tint.foreground,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const AppAudioButton(isAvailable: false),
                      AppFavoriteButton(
                        isFavorite: widget.phrase.isFavorite,
                        onToggle: widget.onFavoriteToggle,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Target Language Phrase (Primary typography)
                  Text(
                    widget.phrase.originalText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: theme.colorScheme.onSurface,
                    ),
                    softWrap: true,
                  ),

                  // Phonetic breakdown if available
                  if (widget.phrase.phonetic != null && widget.phrase.phonetic!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.phrase.phonetic!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      softWrap: true,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.md),

                  // Translation (High contrast, primary teal)
                  Text(
                    widget.phrase.translatedText,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    softWrap: true,
                  ),

                  // Context note in subtle surface container
                  if (widget.phrase.contextNote != null && widget.phrase.contextNote!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                      ),
                      child: Text(
                        widget.phrase.contextNote!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12.5,
                          color: theme.colorScheme.onSurface,
                          height: 1.4,
                        ),
                        softWrap: true,
                      ),
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
