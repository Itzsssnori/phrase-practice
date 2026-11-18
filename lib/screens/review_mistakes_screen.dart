import 'package:material_ui/material_ui.dart';
import '../models/quiz.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Screen detailing incorrect answers and explanations from recent quizzes.
class ReviewMistakesScreen extends StatelessWidget {
  const ReviewMistakesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // PLACEHOLDER: Sample questions displayed for educational review
    final List<QuizQuestion> reviewList = [MockDataService.sampleQuestions.first];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Mistakes'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Deepen Comprehension',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Understanding why a phrase works in context prevents recurring slips.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviewList.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.lg),
              itemBuilder: (context, index) {
                final item = reviewList[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lightError.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Phrase ${index + 1}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.lightError,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          item.originalPhrase,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                              color: AppColors.lightSuccess,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Correct meaning: ${item.options[item.correctIndex]}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.lightSuccess,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                          ),
                          child: Text(
                            item.explanation,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
