import 'package:material_ui/material_ui.dart';
import '../models/phrase.dart';
import '../theme/app_spacing.dart';
import 'app_audio_button.dart';
import 'app_favorite_button.dart';

/// Content-first phrase card emphasizing the target phrase and its translation.
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

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row with audio and favorite actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const AppAudioButton(isAvailable: false),
                  const Spacer(),
                  AppFavoriteButton(
                    isFavorite: phrase.isFavorite,
                    onToggle: onFavoriteToggle,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Original phrase (Target language)
              Text(
                phrase.originalText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                softWrap: true,
              ),

              // Phonetic breakdown if available
              if (phrase.phonetic != null && phrase.phonetic!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  phrase.phonetic!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                  softWrap: true,
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // Primary visual focus: Translation (Native language)
              Text(
                phrase.translatedText,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
                softWrap: true,
              ),

              // Context note if provided
              if (phrase.contextNote != null && phrase.contextNote!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                  ),
                  child: Text(
                    phrase.contextNote!,
                    style: theme.textTheme.bodySmall,
                    softWrap: true,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
