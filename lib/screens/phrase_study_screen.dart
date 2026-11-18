import 'package:material_ui/material_ui.dart';
import '../models/phrase.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_audio_button.dart';
import '../widgets/app_favorite_button.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_secondary_button.dart';

/// Immersive, content-first phrase study screen optimized for calm reading.
class PhraseStudyScreen extends StatefulWidget {
  const PhraseStudyScreen({super.key});

  @override
  State<PhraseStudyScreen> createState() => _PhraseStudyScreenState();
}

class _PhraseStudyScreenState extends State<PhraseStudyScreen> {
  int _currentIndex = 0;
  late List<Phrase> _phrases;

  @override
  void initState() {
    super.initState();
    _phrases = List.from(MockDataService.samplePhrases);
  }

  void _nextPhrase() {
    if (_currentIndex < _phrases.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _previousPhrase() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _toggleFavorite() {
    setState(() {
      final current = _phrases[_currentIndex];
      _phrases[_currentIndex] = current.copyWith(isFavorite: !current.isFavorite);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final phrase = _phrases[_currentIndex];
    final progressLabel = '${_currentIndex + 1} of ${_phrases.length}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Mode'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                ),
                child: Text(
                  progressLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkOnSecondary : AppColors.lightOnSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clean linear progress line
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _phrases.length,
                  minHeight: 4,
                  backgroundColor: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Study Focus Area
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Action buttons row (Audio & Favorite)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                            ),
                            child: Text(
                              phrase.categoryId.toUpperCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkOnSecondary : AppColors.lightOnSecondary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const AppAudioButton(isAvailable: false),
                          AppFavoriteButton(
                            isFavorite: phrase.isFavorite,
                            onToggle: (_) => _toggleFavorite(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Target Phrase
                      Text(
                        phrase.originalText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                          height: 1.35,
                        ),
                        softWrap: true,
                      ),

                      if (phrase.phonetic != null && phrase.phonetic!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          phrase.phonetic!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          softWrap: true,
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xl),

                      // Translation: Visual Focus (Teal green #168B83)
                      Text(
                        'Translation',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        phrase.translatedText,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                        softWrap: true,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Context / Usage explanation card
                      if (phrase.contextNote != null && phrase.contextNote!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              width: 1,
                            ),
                            boxShadow: isDark
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.015),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline_rounded,
                                    size: AppSpacing.iconSm,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Usage Context',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkText : AppColors.lightText,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                phrase.contextNote!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  height: 1.45,
                                ),
                                softWrap: true,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Navigation buttons
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Previous',
                      icon: Icons.chevron_left_rounded,
                      onPressed: _currentIndex > 0 ? _previousPhrase : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppPrimaryButton(
                      label: _currentIndex < _phrases.length - 1 ? 'Next' : 'Finish',
                      icon: _currentIndex < _phrases.length - 1
                          ? Icons.chevron_right_rounded
                          : Icons.check_rounded,
                      onPressed: _currentIndex < _phrases.length - 1
                          ? _nextPhrase
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
