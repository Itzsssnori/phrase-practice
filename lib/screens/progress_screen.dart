import 'package:material_ui/material_ui.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Progress overview screen tracking phrases learned and topic mastery calmly.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = MockDataService.sampleProgress;
    final categories = MockDataService.sampleCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Steady Momentum',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Consistent reading builds intuition faster than cramming.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Metrics grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Phrases Learned',
                    value: '${progress.phrasesLearned}',
                    subtitle: 'of ${progress.totalPhrases} total',
                    icon: Icons.menu_book_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    title: 'Daily Streak',
                    value: '${progress.currentStreakDays} days',
                    subtitle: 'Active habit',
                    icon: Icons.local_fire_department_rounded,
                    accentColor: AppColors.lightAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Quiz Accuracy',
                    value: '${progress.averageAccuracy.toInt()}%',
                    subtitle: '${progress.totalQuizzesTaken} sessions taken',
                    icon: Icons.pie_chart_outline_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    title: 'Completion',
                    value: '${(progress.completionRatio * 100).toInt()}%',
                    subtitle: 'Overall syllabus',
                    icon: Icons.verified_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Topic mastery breakdown
            Text(
              'Topic Mastery',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: categories.map((cat) {
                    final percent = (cat.progress * 100).toInt();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                cat.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$percent%',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: cat.progress,
                              minHeight: 6,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color? accentColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = accentColor ?? theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: AppSpacing.iconMd, color: iconColor),
            const SizedBox(height: AppSpacing.md),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
