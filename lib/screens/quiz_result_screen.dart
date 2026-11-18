import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_secondary_button.dart';

/// Result summary screen shown after concluding a quiz round.
class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Summary'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.lightSuccess.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: AppColors.lightSuccess,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Well Practiced',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'You completed 3 phrases with high contextual accuracy.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Metrics card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricItem(label: 'Accuracy', value: '100%'),
                    Container(height: 36, width: 1, color: theme.dividerColor),
                    _MetricItem(label: 'Reviewed', value: '3 / 3'),
                    Container(height: 36, width: 1, color: theme.dividerColor),
                    _MetricItem(label: 'Pace', value: 'Calm'),
                  ],
                ),
              ),

              const Spacer(),

              AppSecondaryButton(
                label: 'Review Mistakes & Explanations',
                icon: Icons.notes_rounded,
                onPressed: () => context.push('/quiz/review-mistakes'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppPrimaryButton(
                label: 'Return to Home',
                icon: Icons.home_rounded,
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetricItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}
