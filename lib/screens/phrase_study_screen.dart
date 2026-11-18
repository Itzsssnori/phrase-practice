import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/phrase.dart';
import '../services/mock_data_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_audio_button.dart';
import '../widgets/app_favorite_button.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_secondary_button.dart';

/// Immersive, content-first phrase study screen with recall practice and adjustable typography.
class PhraseStudyScreen extends StatefulWidget {
  const PhraseStudyScreen({super.key});

  @override
  State<PhraseStudyScreen> createState() => _PhraseStudyScreenState();
}

class _PhraseStudyScreenState extends State<PhraseStudyScreen> {
  static const String _keyTextSize = 'study_text_size';
  static const String _keyRecallMode = 'study_recall_mode';

  int _currentIndex = 0;
  late List<Phrase> _phrases;

  int _textSizeIndex = 0; // 0: Default, 1: Large (+4/+2/+2), 2: XLarge (+8/+4/+4)
  bool _recallMode = false;
  bool _isTranslationRevealed = false;
  bool _isPronunciationRevealed = false;

  @override
  void initState() {
    super.initState();
    _phrases = List.from(MockDataService.samplePhrases);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _textSizeIndex = prefs.getInt(_keyTextSize) ?? 0;
        _recallMode = prefs.getBool(_keyRecallMode) ?? false;
      });
    }
  }

  Future<void> _cycleTextSize() async {
    final next = (_textSizeIndex + 1) % 3;
    setState(() => _textSizeIndex = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTextSize, next);
  }

  Future<void> _toggleRecallMode() async {
    final next = !_recallMode;
    setState(() {
      _recallMode = next;
      _isTranslationRevealed = false;
      _isPronunciationRevealed = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRecallMode, next);
  }

  void _nextPhrase() {
    if (_currentIndex < _phrases.length - 1) {
      setState(() {
        _currentIndex++;
        _isTranslationRevealed = false;
        _isPronunciationRevealed = false;
      });
    }
  }

  void _previousPhrase() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isTranslationRevealed = false;
        _isPronunciationRevealed = false;
      });
    }
  }

  double get _translationOffset {
    switch (_textSizeIndex) {
      case 1:
        return 4.0;
      case 2:
        return 8.0;
      default:
        return 0.0;
    }
  }

  double get _pronunciationOffset {
    switch (_textSizeIndex) {
      case 1:
        return 2.0;
      case 2:
        return 4.0;
      default:
        return 0.0;
    }
  }

  double get _exampleOffset {
    switch (_textSizeIndex) {
      case 1:
        return 2.0;
      case 2:
        return 4.0;
      default:
        return 0.0;
    }
  }

  String get _textSizeTooltip {
    switch (_textSizeIndex) {
      case 1:
        return 'Text size: Large';
      case 2:
        return 'Text size: Extra Large';
      default:
        return 'Text size: Default';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final phrase = _phrases[_currentIndex];

    final progressValue = (_currentIndex + 1) / _phrases.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spanish'),
        actions: [
          Tooltip(
            message: _textSizeTooltip,
            child: TextButton(
              onPressed: _cycleTextSize,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              child: Text(
                'Aa',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.0 + (_textSizeIndex * 2),
                ),
              ),
            ),
          ),
          Semantics(
            label: _recallMode ? 'Show translation' : 'Hide translation for recall practice',
            child: IconButton(
              icon: Icon(
                _recallMode ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              ),
              tooltip: _recallMode ? 'Recall mode ON' : 'Recall mode OFF',
              onPressed: _toggleRecallMode,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Thin 4px linear progress indicator animated on phrase changes
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              tween: Tween<double>(begin: 0, end: progressValue),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card 1 — Translation focus card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                                ),
                                child: Text(
                                  'ES',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: theme.colorScheme.onPrimaryContainer,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              AppFavoriteButton(
                                isFavorite: phrase.isFavorite,
                                isDisabled: true,
                                disabledTooltip: 'Coming soon',
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Translation / Recall display
                          if (_recallMode && !_isTranslationRevealed) ...[
                            Semantics(
                              label: 'Translation hidden. Tap to reveal.',
                              button: true,
                              child: InkWell(
                                onTap: () => setState(() => _isTranslationRevealed = true),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                    vertical: AppSpacing.xl,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                                    border: Border.all(
                                      color: theme.dividerColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.visibility_outlined,
                                        size: AppSpacing.iconSm,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        'Tap to reveal',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            Semantics(
                              label: 'Translation revealed.',
                              child: Text(
                                phrase.translatedText,
                                style: (theme.textTheme.displaySmall ?? const TextStyle()).copyWith(
                                  fontSize: (theme.textTheme.displaySmall?.fontSize ?? 26.0) + _translationOffset,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                                softWrap: true,
                              ),
                            ),
                          ],

                          const SizedBox(height: AppSpacing.md),
                          const AppAudioButton(isAvailable: false),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Card 2 — Source phrase card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            phrase.originalText,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                            softWrap: true,
                          ),
                          if (phrase.phonetic != null && phrase.phonetic!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            if (_recallMode && !_isPronunciationRevealed) ...[
                              Semantics(
                                label: 'Pronunciation hidden. Tap to reveal.',
                                button: true,
                                child: InkWell(
                                  onTap: () => setState(() => _isPronunciationRevealed = true),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                                      border: Border.all(
                                        color: theme.dividerColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.visibility_outlined,
                                          size: 16,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Text(
                                          'Tap to reveal pronunciation',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Semantics(
                                label: 'Pronunciation: ${phrase.phonetic}',
                                child: Text(
                                  phrase.phonetic!,
                                  style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
                                    fontSize: (theme.textTheme.bodySmall?.fontSize ?? 13.0) + _pronunciationOffset,
                                    fontStyle: FontStyle.italic,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Card 3 — Example sentence card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Example',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            phrase.contextNote != null && phrase.contextNote!.isNotEmpty
                                ? '“${phrase.translatedText}” — ${phrase.contextNote} [PLACEHOLDER EXAMPLE]'
                                : '“${phrase.translatedText}” [PLACEHOLDER EXAMPLE]',
                            style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                              fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 15.0) + _exampleOffset,
                              color: theme.colorScheme.onSurface,
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

            // Navigation row at bottom (outside scroll)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Previous',
                      icon: Icons.chevron_left_outlined,
                      onPressed: _currentIndex > 0 ? _previousPhrase : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppPrimaryButton(
                      label: _currentIndex < _phrases.length - 1 ? 'Next' : 'Done',
                      icon: _currentIndex < _phrases.length - 1
                          ? Icons.chevron_right_outlined
                          : Icons.check_outlined,
                      onPressed: _currentIndex < _phrases.length - 1
                          ? _nextPhrase
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
