import 'package:material_ui/material_ui.dart';
import '../models/phrase.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_audio_button.dart';
import 'app_auth_scope.dart';
import 'app_favorite_button.dart';
import 'app_settings_scope.dart';
import 'app_user_phrase_scope.dart';
import 'require_sign_in.dart';

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
  final bool showCategory;

  const PhraseCard({
    super.key,
    required this.phrase,
    this.onTap,
    this.onFavoriteToggle,
    this.targetLanguageCode,
    this.nativeLanguageCode,
    this.showCategory = true,
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

    final userPhraseCtrl = AppUserPhraseScope.maybeOf(context);
    final isFavorite = userPhraseCtrl?.isFavorite(widget.phrase.id) ?? widget.phrase.isFavorite;
    final isLearned = userPhraseCtrl?.isLearned(widget.phrase.id, targetCode) ?? false;

    // Resolve target and native translations
    final targetTrans = widget.phrase.translationFor(targetCode);
    final nativeTrans = widget.phrase.translationFor(nativeCode);

    final mainText = targetTrans?.text ?? widget.phrase.translatedText;
    final subText = nativeTrans?.text ?? widget.phrase.originalText;
    final pronunciation = targetTrans?.pronunciation ?? widget.phrase.phonetic;
    // Notes explain meaning — always show in the native language.
    final note = nativeTrans?.meaningNote ?? widget.phrase.contextNote;

    return Semantics(
      button: true,
      label: 'Phrase: $mainText. Translation: $subText. Tap to study.',
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          width: double.infinity,
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
                    // Top Row: Category Chip on left (if showCategory), Actions on top-right
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (widget.showCategory)
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
                          )
                        else
                          const SizedBox.shrink(),
                        const Spacer(),
                        if (isLearned) ...[
                          Tooltip(
                            message: 'Learned in ${targetCode.toUpperCase()}',
                            child: Semantics(
                              label: 'Learned',
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 13,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        const AppAudioButton(isAvailable: false),
                        AppFavoriteButton(
                          isFavorite: isFavorite,
                          onToggle: (fav) async {
                            if (widget.onFavoriteToggle != null) {
                              widget.onFavoriteToggle!(fav);
                              return;
                            }
                            if (userPhraseCtrl != null) {
                              final auth = AppAuthScope.maybeOf(context);
                              if (auth == null || !auth.isSignedIn) {
                                final signedIn = await requireSignIn(context);
                                if (!signedIn) return;
                              }
                              final wasFav = userPhraseCtrl.isFavorite(widget.phrase.id);
                              final res = await userPhraseCtrl.toggleFavorite(widget.phrase.id);
                              if (!context.mounted) return;
                              if (res.isError) {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res.errorMessageOrNull ?? 'Could not update favorite.'),
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                  ),
                                );
                              } else if (wasFav && res.isSuccess) {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Removed from favorites'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () => userPhraseCtrl.toggleFavorite(widget.phrase.id),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Main Text: Target Language Translation (largest focus)
                    Text(
                      mainText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      softWrap: true,
                    ),

                    // Sub Text: Native Language Phrase
                    if (subText.isNotEmpty && subText != mainText) ...[
                      const SizedBox(height: 2),
                      Text(
                        subText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                          height: 1.3,
                        ),
                        softWrap: true,
                      ),
                    ],

                    // Pronunciation in small text
                    if (pronunciation != null && pronunciation.isNotEmpty) ...[
                      const SizedBox(height: 2),
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
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                        ),
                        child: Text(
                          note,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.3,
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
