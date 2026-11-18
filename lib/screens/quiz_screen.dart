import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
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
    setState(() => _isAnswerSubmitted = true);
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
    final isDark = theme.brightness == Brightness.dark;
    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1} of ${_questions.length}'),
        leading: CloseButton(onPressed: () => context.pop()),
      ),
      // Use resizeToAvoidBottomInset so soft keyboard doesn't cause overflow
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // --- Progress bar ---
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // --- Prompt label + phrase (fixed height, scrolls only if huge) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  question.prompt,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  question.originalPhrase,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                  // Allow wrapping for long phrases
                  softWrap: true,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // --- Options list (scrollable, takes remaining space) ---
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: question.options.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final optionText = question.options[index];
                  final isSelected = _selectedOption == index;
                  Color borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
                  Color fillColor = theme.colorScheme.surface;

                  if (_isAnswerSubmitted) {
                    if (index == question.correctIndex) {
                      borderColor = isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
                      fillColor = isDark
                          ? AppColors.darkSuccess.withValues(alpha: 0.15)
                          : AppColors.lightSuccessBackground;
                    } else if (isSelected) {
                      borderColor = isDark ? AppColors.darkError : AppColors.lightError;
                      fillColor = isDark
                          ? AppColors.darkError.withValues(alpha: 0.15)
                          : AppColors.lightErrorBackground;
                    }
                  } else if (isSelected) {
                    borderColor = theme.colorScheme.primary;
                    fillColor = isDark
                        ? AppColors.darkPrimaryContainer
                        : AppColors.lightPrimaryContainer;
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
                        border: Border.all(color: borderColor, width: isSelected ? 1.8 : 1),
                      ),
                      child: Row(
                        children: [
                          // Letter badge
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor),
                            ),
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkText : AppColors.lightText,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          // Option text — Expanded prevents horizontal overflow
                          Expanded(
                            child: Text(
                              optionText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.darkText : AppColors.lightText,
                              ),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- Explanation + Action button (always visible at bottom) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Explanation box — only appears after submitting
                  if (_isAnswerSubmitted) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Text(
                        question.explanation,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                  AppPrimaryButton(
                    label: !_isAnswerSubmitted
                        ? 'Check Answer'
                        : (_currentIndex < _questions.length - 1
                            ? 'Continue'
                            : 'See Results'),
                    onPressed: _selectedOption == null
                        ? null
                        : (!_isAnswerSubmitted ? _submitAnswer : _nextQuestion),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
