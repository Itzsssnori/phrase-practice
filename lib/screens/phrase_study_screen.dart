import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/phrase.dart';
import '../models/phrase_translation.dart';
import '../services/browse_data_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_audio_button.dart';
import '../widgets/app_auth_scope.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_message.dart';
import '../widgets/app_favorite_button.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_secondary_button.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/app_user_phrase_scope.dart';
import '../widgets/require_sign_in.dart';

/// Interactive study screen with recall mode, text-size scaling, and full-context cards.
class PhraseStudyScreen extends StatefulWidget {
  final String? initialPhraseSlug;
  final String? categoryId;

  const PhraseStudyScreen({
    super.key,
    this.initialPhraseSlug,
    this.categoryId,
  });

  @override
  State<PhraseStudyScreen> createState() => _PhraseStudyScreenState();
}

class _PhraseStudyScreenState extends State<PhraseStudyScreen> {
  static const String _keyTextSize = 'study_text_size_index';
  static const String _keyRecallMode = 'study_recall_mode';

  final _browseService = BrowseDataService.instance;

  bool _isLoading = true;
  String? _errorMessage;
  List<Phrase> _categoryPhrases = [];
  int _currentIndex = 0;

  // Study screen state
  int _textSizeIndex = 0; // 0: Default, 1: Large (+4), 2: Extra Large (+8)
  bool _recallMode = false;
  bool _isTranslationRevealed = false;
  bool _isPronunciationRevealed = false;
  final Set<String> _recordedRecentPhrases = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadStudyPhrases();
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

  Future<void> _loadStudyPhrases({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final targetSlug = widget.initialPhraseSlug;
    final explicitCat = widget.categoryId;

    // 1. If explicit category is provided, load that category
    if (explicitCat != null && explicitCat.isNotEmpty) {
      final result = await _browseService.getPhrasesByCategory(explicitCat, forceRefresh: forceRefresh);
      if (result.isError) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = result.errorMessageOrNull ?? 'Failed to load category phrases.';
          });
        }
        return;
      }

      _categoryPhrases = result.dataOrNull ?? [];
    } else if (targetSlug != null && targetSlug.isNotEmpty) {
      // 2. If phrase slug is provided without category, fetch the phrase to discover its category
      final phraseResult = await _browseService.getPhraseBySlug(targetSlug);
      if (phraseResult.isSuccess && phraseResult.dataOrNull != null) {
        final phrase = phraseResult.dataOrNull!;
        final catResult = await _browseService.getPhrasesByCategory(phrase.categoryId, forceRefresh: forceRefresh);
        _categoryPhrases = catResult.dataOrNull ?? [phrase];
      } else {
        // Fallback: load all phrases
        final allResult = await _browseService.getAllPhrases(forceRefresh: forceRefresh);
        _categoryPhrases = allResult.dataOrNull ?? [];
      }
    } else {
      // 3. Fallback: load all phrases
      final allResult = await _browseService.getAllPhrases(forceRefresh: forceRefresh);
      _categoryPhrases = allResult.dataOrNull ?? [];
    }

    if (!mounted) return;

    if (_categoryPhrases.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No study phrases found.';
      });
      return;
    }

    // Determine initial index based on target slug
    int initialIdx = 0;
    if (targetSlug != null && targetSlug.isNotEmpty) {
      final found = _categoryPhrases.indexWhere((p) => p.id == targetSlug);
      if (found != -1) {
        initialIdx = found;
      }
    }

    setState(() {
      _currentIndex = initialIdx;
      _isLoading = false;
      _isTranslationRevealed = false;
      _isPronunciationRevealed = false;
    });
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
    if (_currentIndex < _categoryPhrases.length - 1) {
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
    final settings = AppSettingsScope.of(context);

    final targetLangCode = settings.targetLanguageCode;
    final nativeLangCode = settings.nativeLanguageCode;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Phrase Study')),
        body: const Center(child: AppLoadingIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Phrase Study')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: AppErrorMessage(
              title: 'Unable to Load Phrase',
              message: _errorMessage!,
              retryLabel: 'Try Again',
              onRetry: () => _loadStudyPhrases(forceRefresh: true),
            ),
          ),
        ),
      );
    }

    if (_categoryPhrases.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Phrase Study')),
        body: const Center(
          child: AppEmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'No Phrases Available',
            message: 'No study phrases are available right now.',
          ),
        ),
      );
    }

    final phrase = _categoryPhrases[_currentIndex];
    _recordRecentViewIfNeeded(phrase.id);

    final userPhraseCtrl = AppUserPhraseScope.maybeOf(context);
    final isFav = userPhraseCtrl?.isFavorite(phrase.id) ?? false;
    final isLearned = userPhraseCtrl?.isLearned(phrase.id, targetLangCode) ?? false;

    final targetTrans = phrase.translationFor(targetLangCode) ??
        phrase.translationFor('es') ??
        phrase.translations.values.firstOrNull ??
        PhraseTranslation(text: phrase.translatedText);
    final nativeTrans = phrase.translationFor(nativeLangCode) ??
        phrase.translationFor('en') ??
        PhraseTranslation(text: phrase.originalText);

    final progressValue = (_currentIndex + 1) / _categoryPhrases.length;
    final languageLabel = targetLangCode.toUpperCase();

    // Determine available data fields (hide if empty)
    final mainTranslatedText = targetTrans.text;
    final nativePhraseText = nativeTrans.text;
    final pronunciation = targetTrans.pronunciation;
    final targetExample = targetTrans.exampleSentence;
    final nativeExample = nativeTrans.exampleSentence;
    // Notes explain what the phrase means — always show in native language.
    final meaningNote = nativeTrans.meaningNote ?? targetTrans.meaningNote;

    return Scaffold(
      appBar: AppBar(
        title: Text('${targetLangCode.toUpperCase()} Study'),
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
            // Linear progress indicator across the category
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
                    // Field 1 & 5: Target Language Focus Card (Translation + Language Badge)
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
                                  languageLabel,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: theme.colorScheme.onPrimaryContainer,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _buildLearnedToggle(theme, isDark, isLearned, phrase.id, targetLangCode),
                              const Spacer(),
                              AppFavoriteButton(
                                isFavorite: isFav,
                                onToggle: (_) => _handleFavoriteToggle(phrase.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Translation / Recall display (Field 1: Target language in largest text)
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
                              label: 'Translation: $mainTranslatedText',
                              child: Text(
                                mainTranslatedText,
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

                    // Field 2 & 3: Source Native Phrase & Pronunciation
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
                            nativePhraseText,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                            softWrap: true,
                          ),

                          // Field 3: Pronunciation (hide if empty or null)
                          if (pronunciation != null && pronunciation.isNotEmpty) ...[
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
                                label: 'Pronunciation: $pronunciation',
                                child: Text(
                                  pronunciation,
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

                    // Field 4: Example Sentence Card (hide if both target and native examples are empty)
                    if ((targetExample != null && targetExample.isNotEmpty) ||
                        (nativeExample != null && nativeExample.isNotEmpty)) ...[
                      const SizedBox(height: AppSpacing.lg),
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

                            if (targetExample != null && targetExample.isNotEmpty)
                              Text(
                                '“$targetExample”',
                                style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                                  fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 15.0) + _exampleOffset,
                                  color: theme.colorScheme.onSurface,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                                softWrap: true,
                              ),

                            // Smaller line for native example if present
                            if (nativeExample != null && nativeExample.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                nativeExample,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                                softWrap: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    // Meaning Note Card under "Notes" heading (hide if empty)
                    if (meaningNote != null && meaningNote.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
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
                              'Notes',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              meaningNote,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 13.5,
                                color: theme.colorScheme.onSurface,
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
                      label: _currentIndex < _categoryPhrases.length - 1 ? 'Next' : 'Done',
                      icon: _currentIndex < _categoryPhrases.length - 1
                          ? Icons.chevron_right_outlined
                          : Icons.check_outlined,
                      onPressed: _currentIndex < _categoryPhrases.length - 1
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

  void _recordRecentViewIfNeeded(String phraseId) {
    if (_recordedRecentPhrases.contains(phraseId)) return;
    _recordedRecentPhrases.add(phraseId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = AppAuthScope.maybeOf(context);
      if (auth != null && auth.isSignedIn) {
        final userPhraseCtrl = AppUserPhraseScope.maybeOf(context);
        userPhraseCtrl?.recordRecentView(phraseId);
      }
    });
  }

  Widget _buildLearnedToggle(
    ThemeData theme,
    bool isDark,
    bool isLearned,
    String phraseId,
    String targetLangCode,
  ) {
    final label = isLearned ? 'Learned' : 'Mark as learned';
    return Semantics(
      button: true,
      label: isLearned ? 'Marked as learned. Tap to unmark.' : 'Tap to mark as learned',
      child: Tooltip(
        message: isLearned
            ? 'Learned in ${targetLangCode.toUpperCase()}'
            : 'Mark as learned in ${targetLangCode.toUpperCase()}',
        child: Material(
          color: isLearned ? theme.colorScheme.primary : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
            side: BorderSide(
              color: isLearned ? theme.colorScheme.primary : theme.dividerColor,
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _handleLearnedToggle(phraseId, targetLangCode),
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLearned ? Icons.check_rounded : Icons.check_circle_outline_rounded,
                    size: 14,
                    color: isLearned ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: isLearned ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11.5,
                      color: isLearned ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLearnedToggle(String phraseId, String targetLangCode) async {
    final auth = AppAuthScope.maybeOf(context);
    if (auth == null || !auth.isSignedIn) {
      final signedIn = await requireSignIn(context);
      if (!mounted || !signedIn) return;
    }
    if (!mounted) return;
    final userPhraseCtrl = AppUserPhraseScope.maybeOf(context);
    await userPhraseCtrl?.toggleLearned(phraseId, targetLangCode);
  }

  Future<void> _handleFavoriteToggle(String phraseId) async {
    final auth = AppAuthScope.maybeOf(context);
    if (auth == null || !auth.isSignedIn) {
      final signedIn = await requireSignIn(context);
      if (!mounted || !signedIn) return;
    }
    if (!mounted) return;
    final userPhraseCtrl = AppUserPhraseScope.maybeOf(context);
    if (userPhraseCtrl != null) {
      final wasFav = userPhraseCtrl.isFavorite(phraseId);
      final res = await userPhraseCtrl.toggleFavorite(phraseId);
      if (!mounted) return;
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
              onPressed: () => userPhraseCtrl.toggleFavorite(phraseId),
            ),
          ),
        );
      }
    }
  }
}
