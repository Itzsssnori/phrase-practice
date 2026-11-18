import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../services/mock_data_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_primary_button.dart';

/// Quiz setup configuration screen (Quiz tab root).
class QuizSetupScreen extends StatefulWidget {
  const QuizSetupScreen({super.key});

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  int _selectedCount = 5;
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Quiz'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reinforce Comprehension',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Short, thoughtful recall drills designed to cement phrase meaning without gamified stress.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Question count selection
              Text(
                'Number of questions',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [5, 10, 15].map((count) {
                  final isSelected = _selectedCount == count;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: ChoiceChip(
                      label: Text('$count questions'),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedCount = count);
                      },
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Topic selection
              Text(
                'Select Topic',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('All Topics (Mixed)')),
                  ...MockDataService.sampleCategories.map(
                    (cat) => DropdownMenuItem(value: cat.id, child: Text(cat.title)),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // Quiz format card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: theme.colorScheme.primary,
                      size: AppSpacing.iconMd,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Untimed, calm format',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Take your time to understand nuances and explanation notes.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              AppPrimaryButton(
                label: 'Begin Practice Session',
                icon: Icons.play_arrow_rounded,
                onPressed: () => context.push('/quiz/play'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
