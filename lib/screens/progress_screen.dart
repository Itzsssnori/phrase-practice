import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../models/category.dart';
import '../models/language.dart';
import '../models/phrase.dart';
import '../models/quiz_attempt.dart';
import '../services/browse_data_service.dart';
import '../services/progress_calculator.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_auth_scope.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_message.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_progress_scope.dart';
import '../widgets/app_secondary_button.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/app_user_phrase_scope.dart';
import '../widgets/phrase_card.dart';

/// Progress overview screen displaying real per-language learning progress,
/// category breakdown, recent quiz results (from up to the last 20 attempts),
/// and recently studied phrases.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _browseService = BrowseDataService.instance;

  bool _isLoadingCatalog = true;
  String? _catalogError;
  List<Category> _categories = const [];
  List<Phrase> _allPhrases = const [];
  List<Language> _languages = const [];
  String? _requestedUid;

  String? _loadedNativeLang;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nativeCode = AppSettingsScope.of(context).nativeLanguageCode;
    if (_loadedNativeLang != nativeCode) {
      _loadedNativeLang = nativeCode;
      _loadCatalog(nativeLanguageCode: nativeCode);
    }
  }

  Future<void> _loadCatalog({
    String? nativeLanguageCode,
    bool forceRefresh = false,
  }) async {
    final nativeCode = nativeLanguageCode ?? _loadedNativeLang ?? 'en';
    setState(() {
      _isLoadingCatalog = true;
      _catalogError = null;
    });

    final results = await Future.wait([
      _browseService.getCategories(nativeCode, forceRefresh: forceRefresh),
      _browseService.getAllPhrases(forceRefresh: forceRefresh),
      _browseService.getLanguages(forceRefresh: forceRefresh),
    ]);

    if (!mounted) return;

    final catRes = results[0];
    final phraseRes = results[1];
    final langRes = results[2];

    if (catRes.isError || phraseRes.isError) {
      setState(() {
        _isLoadingCatalog = false;
        _catalogError =
            catRes.errorMessageOrNull ?? phraseRes.errorMessageOrNull ?? 'Could not load study data.';
      });
      return;
    }

    setState(() {
      _categories = (catRes.dataOrNull as List<Category>?) ?? const [];
      _allPhrases = (phraseRes.dataOrNull as List<Phrase>?) ?? const [];
      _languages = (langRes.dataOrNull as List<Language>?) ?? const [];
      _isLoadingCatalog = false;
    });
  }

  String _languageName(String code) {
    for (final lang in _languages) {
      if (lang.code == code) return lang.name;
    }
    return code.toUpperCase();
  }

  String _categoryName(String? categoryId, String nativeCode) {
    if (categoryId == null || categoryId.isEmpty) return 'All';
    for (final cat in _categories) {
      if (cat.id == categoryId) return cat.nameFor(nativeCode);
    }
    return categoryId;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final auth = AppAuthScope.of(context);
    final settings = AppSettingsScope.of(context);
    final userPhrases = AppUserPhraseScope.maybeOf(context);
    final progressCtrl = AppProgressScope.maybeOf(context);

    // 1. Auth loading
    if (auth.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Progress')),
        body: const Center(child: AppLoadingIndicator()),
      );
    }

    // 2. Guest state
    if (!auth.isSignedIn || auth.user == null) {
      _requestedUid = null;
      return Scaffold(
        appBar: AppBar(title: const Text('Your Progress')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPrimaryContainer
                            : AppColors.lightPrimaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.trending_up_rounded,
                        size: AppSpacing.iconLg,
                        color: isDark
                            ? AppColors.darkOnPrimaryContainer
                            : AppColors.lightOnPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Track Your Progress',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Sign in or create an account to see how many phrases you have learned, track category progress, and review your quiz scores.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryText,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: AppPrimaryButton(
                        label: 'Sign In',
                        onPressed: () => context.push('/login'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: AppSecondaryButton(
                        label: 'Create Account',
                        onPressed: () => context.push('/register'),
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

    // Trigger lazy one-time load of last 20 quiz attempts for this signed-in user
    final uid = auth.user!.uid;
    if (progressCtrl != null && _requestedUid != uid) {
      _requestedUid = uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          progressCtrl.ensureLoaded(uid);
        }
      });
    }

    // 3. Initial loading state
    final isUserPhrasesLoading = userPhrases?.isLoading ?? false;
    final isAttemptsInitialLoading =
        progressCtrl != null && progressCtrl.isLoading && !progressCtrl.hasLoaded;
    if (_isLoadingCatalog || isUserPhrasesLoading || isAttemptsInitialLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Progress')),
        body: const Center(child: AppLoadingIndicator()),
      );
    }

    // 4. Fatal catalog or user-phrase error state with retry
    if (_catalogError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Progress')),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: AppErrorMessage(
                title: 'Could Not Load Progress',
                message: _catalogError!,
                retryLabel: 'Try Again',
                onRetry: () {
                  _loadCatalog(forceRefresh: true);
                  progressCtrl?.loadForUser(uid, force: true);
                },
              ),
            ),
          ),
        ),
      );
    }

    if (userPhrases != null && userPhrases.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Progress')),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: AppErrorMessage(
                title: 'Could Not Load Study Progress',
                message: userPhrases.errorMessage!,
                retryLabel: 'Try Again',
                onRetry: () {
                  userPhrases.loadForUser(uid);
                  progressCtrl?.loadForUser(uid, force: true);
                },
              ),
            ),
          ),
        ),
      );
    }

    final nativeCode = settings.nativeLanguageCode;
    final targetCode = settings.targetLanguageCode;
    final targetLangName = _languageName(targetCode);

    bool isLearnedFn(String phraseId, String lang) =>
        userPhrases?.isLearned(phraseId, lang) ?? false;

    final overview = ProgressCalculator.computeLanguageProgress(
      allPhrases: _allPhrases,
      targetLanguageCode: targetCode,
      isLearned: isLearnedFn,
    );

    final categoryItems = ProgressCalculator.computeCategoryProgress(
      categories: _categories,
      allPhrases: _allPhrases,
      targetLanguageCode: targetCode,
      isLearned: isLearnedFn,
    );

    final quizStats = progressCtrl?.quizStats ??
        ProgressCalculator.computeQuizStats(const []);
    final quizError = progressCtrl?.errorMessage;

    // Resolve recently studied phrases from in-memory catalog
    final phraseById = <String, Phrase>{
      for (final p in _allPhrases) p.id: p,
    };
    final recentPhrases = <Phrase>[];
    if (userPhrases != null) {
      for (final id in userPhrases.recentPhraseIds) {
        final p = phraseById[id];
        if (p != null) recentPhrases.add(p);
      }
    }

    final isCompletelyEmpty = overview.learnedCount == 0 &&
        quizStats.quizzesTaken == 0 &&
        quizError == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          children: [
            if (isCompletelyEmpty) ...[
              AppEmptyState(
                icon: Icons.auto_stories_outlined,
                title: 'No Progress Yet',
                message:
                    'Mark phrases as learned while studying $targetLangName, or take a practice quiz to see your progress here.',
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: [
                  AppPrimaryButton(
                    label: 'Browse Phrases',
                    icon: Icons.menu_book_rounded,
                    onPressed: () => context.go('/categories'),
                  ),
                  AppSecondaryButton(
                    label: 'Take a Quiz',
                    icon: Icons.quiz_outlined,
                    onPressed: () => context.go('/quiz'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ] else ...[
              // --- 1. Overview Section ---
              Semantics(
                header: true,
                child: Text(
                  'Learning $targetLangName',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                label:
                    '${overview.learnedCount} of ${overview.totalCount} phrases learned in $targetLangName, ${overview.percentage} percent',
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              '${overview.learnedCount} of ${overview.totalCount} learned',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: primaryText,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${overview.percentage}%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: overview.ratio,
                          minHeight: 8,
                          backgroundColor:
                              isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // --- 2. By Category Section ---
              if (categoryItems.isNotEmpty) ...[
                Semantics(
                  header: true,
                  child: Text(
                    'By Category',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < categoryItems.length; i++) ...[
                        _CategoryProgressRow(
                          name: categoryItems[i].category.nameFor(nativeCode),
                          learned: categoryItems[i].learnedCount,
                          total: categoryItems[i].totalCount,
                          ratio: categoryItems[i].ratio,
                        ),
                        if (i < categoryItems.length - 1)
                          const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // --- 3. Quiz Results Section ---
              Semantics(
                header: true,
                child: Text(
                  'Quiz Results',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Based on your last ${quizStats.windowLimit} quizzes',
                style: theme.textTheme.bodySmall?.copyWith(color: secondaryText),
              ),
              const SizedBox(height: AppSpacing.sm),

              if (quizError != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: AppErrorMessage(
                    title: 'Could Not Load Quiz Results',
                    message: quizError,
                    retryLabel: 'Retry',
                    onRetry: () => progressCtrl?.loadForUser(uid, force: true),
                  ),
                )
              else if (quizStats.quizzesTaken == 0)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No quizzes taken yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Complete a practice quiz to see your scores and history here.',
                        style: theme.textTheme.bodySmall?.copyWith(color: secondaryText),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppSecondaryButton(
                        label: 'Start a Quiz',
                        icon: Icons.quiz_outlined,
                        onPressed: () => context.go('/quiz'),
                      ),
                    ],
                  ),
                )
              else ...[
                // Summary stats row (responsive Wrap so narrow widths & 1.5x scale never overflow)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - (AppSpacing.sm * 2)) / 3;
                    final useColumn = cardWidth < 96;
                    final statsCards = [
                      _QuizMetricTile(
                        label: 'Quizzes',
                        value: '${quizStats.quizzesTaken}',
                      ),
                      _QuizMetricTile(
                        label: 'Average',
                        value: '${quizStats.averagePercentRounded}%',
                      ),
                      _QuizMetricTile(
                        label: 'Best',
                        value: '${quizStats.bestPercentRounded}%',
                      ),
                    ];

                    if (useColumn) {
                      return Column(
                        children: [
                          for (var i = 0; i < statsCards.length; i++) ...[
                            SizedBox(width: double.infinity, child: statsCards[i]),
                            if (i < statsCards.length - 1)
                              const SizedBox(height: AppSpacing.sm),
                          ],
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: statsCards[0]),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: statsCards[1]),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: statsCards[2]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Last 10 attempts list
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < quizStats.recentAttempts.length; i++) ...[
                        _AttemptRow(
                          attempt: quizStats.recentAttempts[i],
                          dateLabel: _formatDate(quizStats.recentAttempts[i].takenAt),
                          categoryLabel: _categoryName(
                            quizStats.recentAttempts[i].categoryId,
                            nativeCode,
                          ),
                        ),
                        if (i < quizStats.recentAttempts.length - 1)
                          Divider(
                            height: 1,
                            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
            ],

            // --- 4. Recently Studied Section (hidden when empty) ---
            if (recentPhrases.isNotEmpty) ...[
              Semantics(
                header: true,
                child: Text(
                  'Recently Studied',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (var i = 0; i < recentPhrases.length; i++) ...[
                PhraseCard(
                  phrase: recentPhrases[i],
                  onTap: () {
                    final p = recentPhrases[i];
                    context.push('/phrase-study/${p.id}?category=${p.categoryId}');
                  },
                ),
                if (i < recentPhrases.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryProgressRow extends StatelessWidget {
  final String name;
  final int learned;
  final int total;
  final double ratio;

  const _CategoryProgressRow({
    required this.name,
    required this.learned,
    required this.total,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: '$name: $learned of $total learned',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                  softWrap: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$learned of $total learned',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizMetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _QuizMetricTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttemptRow extends StatelessWidget {
  final QuizAttempt attempt;
  final String dateLabel;
  final String categoryLabel;

  const _AttemptRow({
    required this.attempt,
    required this.dateLabel,
    required this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: '$categoryLabel on $dateLabel, score ${attempt.score} of ${attempt.total}',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                    softWrap: true,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '${attempt.score} / ${attempt.total}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
