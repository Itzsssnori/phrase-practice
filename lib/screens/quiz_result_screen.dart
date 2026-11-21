import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../models/phrase.dart';
import '../models/quiz.dart';
import '../services/browse_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_auth_scope.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_quiz_scope.dart';
import '../widgets/app_secondary_button.dart';
import '../widgets/localized_phrase_text.dart';
import '../widgets/require_sign_in.dart';

/// Result summary screen shown after concluding a quiz round.
class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({super.key});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  final _browseService = BrowseDataService.instance;
  List<Phrase> _allPhrases = [];

  @override
  void initState() {
    super.initState();
    _loadAllPhrases();
  }

  Future<void> _loadAllPhrases() async {
    final res = await _browseService.getAllPhrases();
    if (mounted && res.isSuccess) {
      setState(() => _allPhrases = res.dataOrNull ?? []);
    }
  }

  String _getCalmMessage(double percentage) {
    if (percentage >= 100) {
      return 'Outstanding recall, every phrase mastered.';
    } else if (percentage >= 80) {
      return 'Great recall session, building strong familiarity.';
    } else if (percentage >= 50) {
      return 'Good practice round, steady repetition builds lasting recall.';
    } else {
      return 'Keep going, steady review turns new phrases into second nature.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizCtrl = AppQuizScope.maybeOf(context);

    // Browser refresh or direct navigation protection: return safely to /quiz
    if (quizCtrl == null || quizCtrl.lastResult == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/quiz');
      });
      return const Scaffold(
        body: Center(child: AppLoadingIndicator()),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = AppAuthScope.maybeOf(context);
    final isSignedIn = auth != null && auth.isSignedIn;

    final result = quizCtrl.lastResult!;
    final score = result.correctAnswers;
    final total = result.totalQuestions;
    final percentage = result.scorePercentage;
    final mistakes = result.mistakes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Summary'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.md),

              // Success/Completion Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSuccess.withValues(alpha: 0.15)
                      : AppColors.lightSuccessBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 42,
                  color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                'Session Complete',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _getCalmMessage(percentage),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Score Card (Accuracy and Raw Score)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.lg,
                  horizontal: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score / $total',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Score',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${percentage.round()}%',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Accuracy',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- Signed-In: Save Attempt Failure & Retry ---
              if (isSignedIn && quizCtrl.saveAttemptError != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
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
                        Icons.cloud_off_rounded,
                        size: 20,
                        color: isDark ? AppColors.darkError : AppColors.lightError,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          "Couldn't save this result",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkError : AppColors.lightError,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: quizCtrl.isSavingAttempt
                            ? null
                            : () {
                                final uid = auth.user?.uid;
                                if (uid != null) {
                                  quizCtrl.retrySaveAttempt(uid);
                                }
                              },
                        child: quizCtrl.isSavingAttempt
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],

              // --- Guest Mode Sign-in Prompt ---
              if (!isSignedIn) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
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
                      Icon(
                        Icons.account_circle_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: AppSpacing.iconMd,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Sign in to save your results',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton(
                        onPressed: () async => requireSignIn(context),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                ),
              ],

              // --- Missed Phrases Section ---
              if (mistakes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'MISSED PHRASES (${mistakes.length})',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mistakes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final mistake = mistakes[index];
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LocalizedPhraseText(
                            mistake.question.originalPhrase,
                            languageCode:
                                mistake.question.direction == QuizDirection.nativeToTarget
                                    ? mistake.question.nativeLanguageCode
                                    : mistake.question.targetLanguageCode,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : AppColors.lightText,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                                color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: LocalizedPhraseText(
                                  'Correct: ${mistake.correctAnswer}',
                                  languageCode:
                                      mistake.question.direction == QuizDirection.nativeToTarget
                                          ? mistake.question.targetLanguageCode
                                          : mistake.question.nativeLanguageCode,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.cancel_outlined,
                                size: 16,
                                color: isDark ? AppColors.darkError : AppColors.lightError,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: LocalizedPhraseText(
                                  'Your answer: ${mistake.selectedAnswer}',
                                  languageCode:
                                      mistake.question.direction == QuizDirection.nativeToTarget
                                          ? mistake.question.targetLanguageCode
                                          : mistake.question.nativeLanguageCode,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark ? AppColors.darkError : AppColors.lightError,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: AppSpacing.xxl),

              // Action buttons: "Review mistakes", "Try again", "Done"
              if (mistakes.isNotEmpty) ...[
                AppSecondaryButton(
                  label: 'Review Mistakes',
                  icon: Icons.notes_rounded,
                  onPressed: () => context.push('/quiz/review-mistakes'),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              AppSecondaryButton(
                label: 'Try Again',
                icon: Icons.replay_rounded,
                onPressed: () {
                  final restarted = quizCtrl.restartQuiz(_allPhrases);
                  if (restarted && mounted) {
                    context.pushReplacement('/quiz/play');
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),

              AppPrimaryButton(
                label: 'Done',
                icon: Icons.check_rounded,
                onPressed: () => context.go('/quiz'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
