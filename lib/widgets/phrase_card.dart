import 'package:material_ui/material_ui.dart';
import '../models/phrase.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_audio_button.dart';
import 'app_favorite_button.dart';
import 'app_settings_scope.dart';

/// Minimalist, approachable phrase card prioritizing legibility and context.
///
/// Displays target-language translation as the main text, native-language phrase
/// below it, and pronunciation in small italic text.
class PhraseCard extends StatefulWidget {
  final Phrase phrase;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onFavoriteToggle;
  final String? targetLanguageCode;
  final String? nativeLanguageCode;

  const PhraseCard({
    super.key,
    required this.phrase,
    this.onTap,
    this.onFavoriteToggle,
    this.targetLanguageCode,
    this.nativeLanguageCode,
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

    // Read active language codes from settings scope if not explicitly passed
    final settings = AppSettingsScope.maybeOf(context);
    final targetCode = widget.targetLanguageCode ?? settings?.targetLanguageCode ?? 'es';
    final nativeCode = widget.nativeLanguageCode ?? settings?.nativeLanguageCode ?? 'en';

    // Resolve target and native translations
    final targetTrans = widget.phrase.translationFor(targetCode);
    final nativeTrans = widget.phrase.translationFor(nativeCode);

    final mainText = targetTrans?.text ?? widget.phrase.translatedText;
    final subText = nativeTrans?.text ?? widget.phrase.originalText;
    final pronunciation = targetTrans?.pronunciation ?? widget.phrase.phonetic;
    final note = targetTrans?.meaningNote ?? widget.phrase.contextNote;

    return Semantics(
      button: true,
      label: 'Phrase: $mainText. Translation: $subText. Tap to study.',
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
                    // Top Action & Category bar
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Container(
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
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const AppAudioButton(isAvailable: false),
                        AppFavoriteButton(
                          isFavorite: widget.phrase.isFavorite,
                          onToggle: widget.onFavoriteToggle,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Main Text: Target Language Translation (largest focus)
                    Text(
                      mainText,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      softWrap: true,
                    ),

                    // Sub Text: Native Language Phrase
                    if (subText.isNotEmpty && subText != mainText) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                        softWrap: true,
                      ),
                    ],

                    // Pronunciation in small text
                    if (pronunciation != null && pronunciation.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        pronunciation,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12.0,
                        ),
                        softWrap: true,
                      ),
                    ],

                    // Meaning / Context Note if available
                    if (note != null && note.isNotEmpty) ...[
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
                          note,
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
      ),
    );
  }
}
