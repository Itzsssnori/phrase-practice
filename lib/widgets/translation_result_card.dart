import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../models/language.dart';
import '../models/translation_entry.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_audio_button.dart';
import 'localized_phrase_text.dart';

/// Shared plain-text result card for AI translations, reused on both
/// [TranslatorScreen] and [TranslatorHistoryScreen].
class TranslationResultCard extends StatelessWidget {
  final TranslationResult result;
  final bool showInputPhrase;

  const TranslationResultCard({
    super.key,
    required this.result,
    this.showInputPhrase = false,
  });

  Future<void> _copyTranslation(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: result.translatedText));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Translation copied.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surfaceVariant = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: language pair + plain-text "AI translation" badge (+ "From history" if cached)
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${result.sourceLanguageName} → ${result.targetLanguageName}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: secondaryText,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Text(
                      'AI translation',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: secondaryText,
                      ),
                    ),
                  ),
                  if (result.fromHistory)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPrimaryContainer
                            : AppColors.lightPrimaryContainer,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                      ),
                      child: Text(
                        'From history',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkOnPrimaryContainer
                              : AppColors.lightOnPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),

              if (showInputPhrase && result.inputText.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                LocalizedPhraseText(
                  result.inputText,
                  languageCode: result.sourceLanguageCode,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: secondaryText,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // Largest text: the translation (plain text only, localized font & locale)
              Semantics(
                label: 'Translation in ${result.targetLanguageName}: ${result.translatedText}',
                child: SelectableText(
                  result.translatedText,
                  style: LocalizedPhraseText.styleFor(
                    theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                      height: 1.3,
                    ),
                    result.targetLanguageCode,
                  ),
                ),
              ),

              // Pronunciation hint labeled with target language's pronunciationSystem
              if (result.pronunciation.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Semantics(
                  label:
                      '${Language.defaultPronunciationSystemFor(result.targetLanguageCode)}: ${result.pronunciation}',
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${Language.defaultPronunciationSystemFor(result.targetLanguageCode)}:',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: secondaryText,
                        ),
                      ),
                      Text(
                        result.pronunciation,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.primary,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ],

              // Action row: Audio button + Copy button
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppAudioButton(
                    text: result.translatedText,
                    languageCode: result.targetLanguageCode,
                    languageName: result.targetLanguageName,
                    utteranceId:
                        'translator-main-${result.targetLanguageCode}-${result.translatedText}',
                  ),
                  Semantics(
                    button: true,
                    label: 'Copy translation',
                    child: OutlinedButton.icon(
                      onPressed: () => _copyTranslation(context),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy'),
                    ),
                  ),
                ],
              ),

              // Example sentence + example translation
              if (result.exampleSentence.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Example',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          AppAudioButton(
                            text: result.exampleSentence,
                            languageCode: result.targetLanguageCode,
                            languageName: result.targetLanguageName,
                            utteranceId:
                                'translator-example-${result.targetLanguageCode}-${result.exampleSentence}',
                            isCompact: true,
                            actionPrefix: 'Play example',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      LocalizedPhraseText(
                        result.exampleSentence,
                        languageCode: result.targetLanguageCode,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: primaryText,
                          height: 1.4,
                        ),
                      ),
                      if (result.exampleTranslation.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        LocalizedPhraseText(
                          result.exampleTranslation,
                          languageCode: result.sourceLanguageCode,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondaryText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Optional note under "Notes"
              if (result.note.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        result.note,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: primaryText,
                          height: 1.45,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'AI translations can contain mistakes. For anything important, like allergies or emergencies, check with a speaker.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: secondaryText,
            height: 1.4,
          ),
          softWrap: true,
        ),
      ],
    );
  }
}
