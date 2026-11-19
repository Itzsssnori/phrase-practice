import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../models/phrase.dart';
import '../services/browse_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_quiz_scope.dart';
import '../widgets/phrase_card.dart';

/// Screen detailing incorrect answers from the most recent quiz round,
/// rendering them as interactive phrase cards and offering focused repeat drills.
class ReviewMistakesScreen extends StatefulWidget {
  const ReviewMistakesScreen({super.key});

  @override
  State<ReviewMistakesScreen> createState() => _ReviewMistakesScreenState();
}

class _ReviewMistakesScreenState extends State<ReviewMistakesScreen> {
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

  @override
  Widget build(BuildContext context) {
    final quizCtrl = AppQuizScope.maybeOf(context);

    // Protection against direct access or browser refresh
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

    final result = quizCtrl.lastResult!;
    final mistakes = result.mistakes;
    final targetCode = result.targetLanguageCode;

    if (mistakes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Mistakes')),
        body: SafeArea(
          child: AppEmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'No Mistakes to Review',
            message: 'You scored 100% on your last session. Keep up the excellent work!',
            actionLabel: 'Return to Quiz',
            onAction: () => context.go('/quiz'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Mistakes'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          children: [
            Text(
              'Deepen Comprehension',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Understanding why a phrase works in context prevents recurring slips. Tap any card to view full context notes.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // "Practice these again" Primary Action
            AppPrimaryButton(
              label: 'Practice These Again',
              icon: Icons.replay_rounded,
              onPressed: () {
                final started = quizCtrl.practiceMistakes(_allPhrases);
                if (started && mounted) {
                  context.pushReplacement('/quiz/play');
                }
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Missed Phrases as PhraseCard widgets
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mistakes.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final mistake = mistakes[index];
                final phrase = mistake.phrase;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Answer comparison badge
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkError.withValues(alpha: 0.12)
                            : AppColors.lightErrorBackground,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppSpacing.radiusCard),
                          topRight: Radius.circular(AppSpacing.radiusCard),
                        ),
                        border: Border.all(
                          color: isDark ? AppColors.darkError : AppColors.lightError,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: isDark ? AppColors.darkError : AppColors.lightError,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Your answer: ${mistake.selectedAnswer}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isDark ? AppColors.darkError : AppColors.lightError,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Standard interactive PhraseCard
                    PhraseCard(
                      phrase: phrase,
                      targetLanguageCode: targetCode,
                      onTap: () => context.push(
                        '/phrase-study/${phrase.id}?category=${phrase.categoryId}',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
