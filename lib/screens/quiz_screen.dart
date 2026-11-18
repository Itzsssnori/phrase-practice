import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../models/quiz.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_primary_button.dart';

/// Active quiz execution screen with immediate constructive feedback.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final List<QuizQuestion> _questions = MockDataService.sampleQuestions;
  int _currentIndex = 0;
  int? _selectedOption;
  bool _isAnswerSubmitted = false;

  void _submitAnswer() {
    if (_selectedOption == null) return;

    setState(() {
      _isAnswerSubmitted = true;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isAnswerSubmitted = false;
      });
    } else {
      context.pushReplacement('/quiz/result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1} of ${_questions.length}'),
        leading: CloseButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text(
                question.prompt,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Phrase being tested
              Text(
                question.originalPhrase,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Options
              Expanded(
                child: ListView.separated(
                  itemCount: question.options.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final optionText = question.options[index];
                    final isSelected = _selectedOption == index;
                    Color borderColor = theme.dividerColor;
                    Color fillColor = theme.colorScheme.surface;

                    if (_isAnswerSubmitted) {
                      if (index == question.correctIndex) {
                        borderColor = AppColors.lightSuccess;
                        fillColor = AppColors.lightSuccess.withValues(alpha: 0.1);
                      } else if (isSelected) {
                        borderColor = AppColors.lightError;
                        fillColor = AppColors.lightError.withValues(alpha: 0.1);
                      }
                    } else if (isSelected) {
                      borderColor = theme.colorScheme.primary;
                      fillColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
                    }

                    return InkWell(
                      onTap: _isAnswerSubmitted
                          ? null
                          : () => setState(() => _selectedOption = index),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                String.fromCharCode(65 + index), // A, B, C, D
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                optionText,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (_isAnswerSubmitted) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                  ),
                  child: Text(
                    question.explanation,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],

              AppPrimaryButton(
                label: !_isAnswerSubmitted
                    ? 'Check Answer'
                    : (_currentIndex < _questions.length - 1 ? 'Continue' : 'See Results'),
                onPressed: _selectedOption == null
                    ? null
                    : (!_isAnswerSubmitted ? _submitAnswer : _nextQuestion),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
