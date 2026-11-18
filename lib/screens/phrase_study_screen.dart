import 'package:material_ui/material_ui.dart';
import '../models/phrase.dart';
import '../services/mock_data_service.dart';
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
    final phrase = _phrases[_currentIndex];
    final progressLabel = '${_currentIndex + 1} of ${_phrases.length}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Mode'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Text(
                progressLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linear step indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _phrases.length,
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Study Focus Area
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Action buttons row (Audio & Favorite)
                      Row(
                        children: [
                          const AppAudioButton(isAvailable: false),
                          const Spacer(),
                          AppFavoriteButton(
                            isFavorite: phrase.isFavorite,
                            onToggle: (_) => _toggleFavorite(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Target phrase
                      Text(
                        phrase.originalText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        softWrap: true,
                      ),

                      if (phrase.phonetic != null && phrase.phonetic!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          phrase.phonetic!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          softWrap: true,
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xxl),

                      // Translation: Largest, highest priority text on the study screen
                      Text(
                        'Translation',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        phrase.translatedText,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                        softWrap: true,
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Context / Usage explanation card
                      if (phrase.contextNote != null && phrase.contextNote!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline_rounded,
                                    size: AppSpacing.iconSm,
                                    color: theme.colorScheme.secondary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Usage Context',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                phrase.contextNote!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.5,
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

              const SizedBox(height: AppSpacing.lg),

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
