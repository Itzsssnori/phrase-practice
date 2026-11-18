import 'package:material_ui/material_ui.dart';
import '../models/phrase.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_audio_button.dart';
import 'app_favorite_button.dart';

/// Minimalist, approachable phrase card prioritizing legibility and context.
class PhraseCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
                        color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                      ),
                      child: Text(
                        phrase.categoryId.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark ? AppColors.darkOnSecondary : AppColors.lightOnSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const AppAudioButton(isAvailable: false),
                    AppFavoriteButton(
                      isFavorite: phrase.isFavorite,
                      onToggle: onFavoriteToggle,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Target Language Phrase (Primary typography)
                Text(
                  phrase.originalText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                  softWrap: true,
                ),

                // Phonetic breakdown if available
                if (phrase.phonetic != null && phrase.phonetic!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    phrase.phonetic!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    softWrap: true,
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                // Translation (Teal green #168B83, high contrast, clean)
                Text(
                  phrase.translatedText,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  softWrap: true,
                ),

                // Context note in gentle rounded container
                if (phrase.contextNote != null && phrase.contextNote!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                    ),
                    child: Text(
                      phrase.contextNote!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12.5,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
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
    );
  }
}
