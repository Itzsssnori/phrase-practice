import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../models/category.dart';
import '../models/phrase.dart';
import '../models/quiz.dart';
import '../services/browse_data_service.dart';
import '../services/quiz_attempt_repository.dart';
import '../services/quiz_generator.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_auth_scope.dart';
import '../widgets/app_error_message.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_quiz_scope.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/language_picker_bottom_sheet.dart';

/// Quiz setup configuration screen (Quiz tab root).
class QuizSetupScreen extends StatefulWidget {
  final QuizAttemptRepository? attemptRepository;

  const QuizSetupScreen({super.key, this.attemptRepository});

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  final _browseService = BrowseDataService.instance;
  late final QuizAttemptRepository _attemptRepo;

  int _selectedCount = 5;
  String _selectedCategory = 'all';
  QuizDirection _selectedDirection = QuizDirection.nativeToTarget;

  bool _isLoadingData = true;
  String? _dataError;
  List<Category> _categories = [];
  List<Phrase> _allPhrases = [];

  bool _isLoadingRecent = false;
  String? _recentError;
  List<QuizAttempt> _recentAttempts = [];
  String? _lastLoadedUid;

  @override
  void initState() {
    super.initState();
    _attemptRepo = widget.attemptRepository ?? FirestoreQuizAttemptRepository();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSetupData();

    final auth = AppAuthScope.maybeOf(context);
    final uid = auth?.user?.uid;
    if (auth != null && auth.isSignedIn && uid != null && uid != _lastLoadedUid) {
      _lastLoadedUid = uid;
      _loadRecentAttempts(uid);
    } else if (auth == null || !auth.isSignedIn) {
      _lastLoadedUid = null;
      _recentAttempts = [];
    }
  }

  Future<void> _loadSetupData() async {
    final settings = AppSettingsScope.maybeOf(context);
    final nativeCode = settings?.nativeLanguageCode ?? 'en';

    setState(() {
      _isLoadingData = true;
      _dataError = null;
    });

    final catRes = await _browseService.getCategories(nativeCode);
    final phraseRes = await _browseService.getAllPhrases();

    if (!mounted) return;

    if (phraseRes.isError) {
      setState(() {
        _isLoadingData = false;
        _dataError = phraseRes.errorMessageOrNull ?? 'Failed to load phrases.';
      });
      return;
    }

    setState(() {
      _categories = catRes.dataOrNull ?? [];
      _allPhrases = phraseRes.dataOrNull ?? [];
      _isLoadingData = false;
    });
  }

  Future<void> _loadRecentAttempts(String uid) async {
    setState(() {
      _isLoadingRecent = true;
      _recentError = null;
    });

    final res = await _attemptRepo.getRecentAttempts(uid, limit: 5);
    if (!mounted) return;

    setState(() {
      _isLoadingRecent = false;
      if (res.isSuccess) {
        _recentAttempts = res.dataOrNull ?? [];
      } else {
        _recentError = res.errorMessageOrNull ?? 'Could not load recent attempts.';
      }
    });
  }

  void _startQuiz() {
    final settings = AppSettingsScope.of(context);
    final quizCtrl = AppQuizScope.of(context);

    final success = quizCtrl.startQuiz(
      allPhrases: _allPhrases,
      nativeLanguageCode: settings.nativeLanguageCode,
      targetLanguageCode: settings.targetLanguageCode,
      categoryId: _selectedCategory,
      questionCount: _selectedCount,
      direction: _selectedDirection,
    );

    if (success && mounted) {
      context.push('/quiz/play');
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final m = months[dt.month - 1];
    return '$m ${dt.day}, ${dt.year}';
  }

  String _resolveCategoryTitle(String? categoryId) {
    if (categoryId == null || categoryId == 'all') return 'All Topics';
    final match = _categories.where((c) => c.id == categoryId).firstOrNull;
    if (match != null) return match.title;
    return categoryId[0].toUpperCase() + categoryId.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final settings = AppSettingsScope.maybeOf(context);
    final nativeCode = settings?.nativeLanguageCode ?? 'en';
    final targetCode = settings?.targetLanguageCode ?? 'es';

    final auth = AppAuthScope.maybeOf(context);
    final isSignedIn = auth != null && auth.isSignedIn;

    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Practice Quiz')),
        body: const Center(child: AppLoadingIndicator()),
      );
    }

    if (_dataError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Practice Quiz')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: AppErrorMessage(
              title: 'Unable to Load Practice Questions',
              message: _dataError!,
              retryLabel: 'Retry',
              onRetry: _loadSetupData,
            ),
          ),
        ),
      );
    }

    // Evaluate eligible question pool
    final eligiblePool = QuizGenerator.getEligiblePhrases(
      _allPhrases,
      nativeLanguageCode: nativeCode,
      targetLanguageCode: targetCode,
      categoryId: _selectedCategory,
    );
    final canStart = eligiblePool.length >= 4;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Quiz'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recall Practice',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Short, thoughtful recall drills designed to cement phrase meaning without gamified stress.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Active Language Pair Selector Chip
              InkWell(
                onTap: () => LanguagePickerBottomSheet.showPairPicker(context),
                borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkPrimaryContainer : AppColors.lightPrimaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${nativeCode.toUpperCase()}  →  ${targetCode.toUpperCase()}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Question count selection (5, 10, 20)
              Text(
                'Questions',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [5, 10, 20].map((count) {
                  final isSelected = _selectedCount == count;
                  return ChoiceChip(
                    label: Text('$count questions'),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedCount = count);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Topic selection
              Text(
                'Topic Focus',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('All Topics (Mixed)', overflow: TextOverflow.ellipsis),
                  ),
                  ..._categories.map(
                    (cat) => DropdownMenuItem(
                      value: cat.id,
                      child: Text(cat.title, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // Drill Direction Selection
              Text(
                'Drill Direction',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ChoiceChip(
                    label: const Text('Native to Target'),
                    selected: _selectedDirection == QuizDirection.nativeToTarget,
                    onSelected: (val) {
                      if (val) setState(() => _selectedDirection = QuizDirection.nativeToTarget);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Target to Native'),
                    selected: _selectedDirection == QuizDirection.targetToNative,
                    onSelected: (val) {
                      if (val) setState(() => _selectedDirection = QuizDirection.targetToNative);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Mixed'),
                    selected: _selectedDirection == QuizDirection.mixed,
                    onSelected: (val) {
                      if (val) setState(() => _selectedDirection = QuizDirection.mixed);
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Format Info Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPrimaryContainer
                            : AppColors.lightPrimaryContainer,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        color: isDark
                            ? AppColors.darkOnPrimaryContainer
                            : AppColors.lightOnPrimaryContainer,
                        size: AppSpacing.iconSm,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Untimed, calm format',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : AppColors.lightText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Immediate feedback with pronunciation and context notes.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Pool size warning if < 4 phrases
              if (!canStart) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkError.withValues(alpha: 0.15)
                        : AppColors.lightErrorBackground,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                    border: Border.all(
                      color: isDark ? AppColors.darkError : AppColors.lightError,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: isDark ? AppColors.darkError : AppColors.lightError,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Only ${eligiblePool.length} phrase(s) available in this topic with active translations. At least 4 phrases are needed to generate quiz options.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkError : AppColors.lightError,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Start button
              AppPrimaryButton(
                label: 'Begin Practice Session',
                icon: Icons.play_arrow_rounded,
                onPressed: canStart ? _startQuiz : null,
              ),

              // --- Signed-In: Recent Quizzes ---
              if (isSignedIn) ...[
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'RECENT QUIZZES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_isLoadingRecent) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: AppLoadingIndicator()),
                  ),
                ] else if (_recentError != null) ...[
                  AppErrorMessage(
                    title: 'Could not load recent quizzes',
                    message: _recentError!,
                    retryLabel: 'Retry',
                    onRetry: () {
                      final u = auth.user?.uid;
                      if (u != null) _loadRecentAttempts(u);
                    },
                  ),
                ] else if (_recentAttempts.isNotEmpty) ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentAttempts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final attempt = _recentAttempts[index];
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkPrimaryContainer
                                    : AppColors.lightPrimaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _resolveCategoryTitle(attempt.categoryId),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkText : AppColors.lightText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDate(attempt.takenAt),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${attempt.score} / ${attempt.total}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
