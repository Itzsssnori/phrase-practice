import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../models/language.dart';
import '../models/quiz.dart';
import '../services/speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_audio_button.dart';
import '../widgets/app_auth_scope.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_quiz_scope.dart';
import '../widgets/app_speech_scope.dart';
import '../widgets/localized_phrase_text.dart';

/// Active practice quiz screen featuring immediate constructive feedback.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  SpeechService? _speechService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _speechService = AppSpeechScope.maybeOf(context);
  }

  @override
  void dispose() {
    final speech = _speechService;
    if (speech != null) {
      unawaited(speech.stop());
    }
    super.dispose();
  }

  Future<bool> _confirmExit(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Quiz?'),
        content: const Text(
          'Your progress in this session will be discarded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final quizCtrl = AppQuizScope.maybeOf(context);

    // Browser refresh or direct navigation protection: return safely to /quiz
    if (quizCtrl == null || !quizCtrl.hasActiveQuiz || quizCtrl.currentQuestion == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/quiz');
      });
      return const Scaffold(
        body: Center(child: AppLoadingIndicator()),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final question = quizCtrl.currentQuestion!;
    final currentIndex = quizCtrl.currentIndex;
    final total = quizCtrl.totalQuestions;
    final selectedOption = quizCtrl.currentSelectedOption;
    final isAnswerSubmitted = quizCtrl.isAnswerSubmitted;
    final progress = (currentIndex + 1) / total;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _confirmExit(context);
        if (shouldLeave && context.mounted) {
          quizCtrl.discardQuiz();
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${currentIndex + 1} of $total'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Leave quiz',
            onPressed: () async {
              final shouldLeave = await _confirmExit(context);
              if (shouldLeave && context.mounted) {
                quizCtrl.discardQuiz();
                context.pop();
              }
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // --- Progress indicator ---
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
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
              const SizedBox(height: AppSpacing.lg),

              // --- Scrollable Question & Options Body ---
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Prompt label
                      Text(
                        question.prompt,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Original phrase
                      LocalizedPhraseText(
                        question.originalPhrase,
                        languageCode: question.direction == QuizDirection.nativeToTarget
                            ? question.nativeLanguageCode
                            : question.targetLanguageCode,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                          height: 1.3,
                        ),
                      ),

                      // Audio button on question card when direction is target -> native
                      if (question.direction == QuizDirection.targetToNative) ...[
                        const SizedBox(height: AppSpacing.xs),
                        AppAudioButton(
                          text: question.originalPhrase,
                          languageCode: question.targetLanguageCode,
                          utteranceId:
                              'quiz-question-${question.phrase.id}-${question.targetLanguageCode}',
                        ),
                      ],

                      // Target-language pronunciation revealed after answering
                      if (isAnswerSubmitted &&
                          question.pronunciation != null &&
                          question.pronunciation!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${Language.defaultPronunciationSystemFor(question.targetLanguageCode)}:',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            Text(
                              question.pronunciation!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.primary,
                              ),
                              softWrap: true,
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xl),

                      // Options list
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: question.options.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final optionText = question.options[index];
                          final isSelected = selectedOption == index;
                          final isCorrect = index == question.correctIndex;

                          Color borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
                          Color fillColor = theme.colorScheme.surface;
                          Widget? feedbackBadge;

                          if (isAnswerSubmitted) {
                            if (isCorrect) {
                              borderColor = isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
                              fillColor = isDark
                                  ? AppColors.darkSuccess.withValues(alpha: 0.15)
                                  : AppColors.lightSuccessBackground;
                              feedbackBadge = Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Correct',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                                    ),
                                  ),
                                ],
                              );
                            } else if (isSelected) {
                              borderColor = isDark ? AppColors.darkError : AppColors.lightError;
                              fillColor = isDark
                                  ? AppColors.darkError.withValues(alpha: 0.15)
                                  : AppColors.lightErrorBackground;
                              feedbackBadge = Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cancel_rounded,
                                    size: 16,
                                    color: isDark ? AppColors.darkError : AppColors.lightError,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Incorrect',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkError : AppColors.lightError,
                                    ),
                                  ),
                                ],
                              );
                            }
                          } else if (isSelected) {
                            borderColor = theme.colorScheme.primary;
                            fillColor = isDark
                                ? AppColors.darkPrimaryContainer
                                : AppColors.lightPrimaryContainer;
                          }

                          return InkWell(
                            onTap: isAnswerSubmitted ? null : () => quizCtrl.selectOption(index),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: fillColor,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                                border: Border.all(
                                  color: borderColor,
                                  width: (isSelected || (isAnswerSubmitted && isCorrect)) ? 2 : 1,
                                ),
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

                                  // Option text
                                  Expanded(
                                    child: LocalizedPhraseText(
                                      optionText,
                                      languageCode:
                                          question.direction == QuizDirection.nativeToTarget
                                              ? question.targetLanguageCode
                                              : question.nativeLanguageCode,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppColors.darkText : AppColors.lightText,
                                      ),
                                    ),
                                  ),

                                  // Feedback badge with Icon + Text
                                  if (feedbackBadge != null) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    feedbackBadge,
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Feedback panel after submitting (includes audio button when answer is target-language text)
                      if (isAnswerSubmitted &&
                          (question.direction == QuizDirection.nativeToTarget ||
                              question.explanation.isNotEmpty)) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (question.direction == QuizDirection.nativeToTarget) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: LocalizedPhraseText(
                                        question.options[question.correctIndex],
                                        languageCode: question.targetLanguageCode,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkText : AppColors.lightText,
                                        ),
                                      ),
                                    ),
                                    AppAudioButton(
                                      text: question.options[question.correctIndex],
                                      languageCode: question.targetLanguageCode,
                                      utteranceId:
                                          'quiz-answer-${question.phrase.id}-${question.targetLanguageCode}',
                                      isCompact: true,
                                    ),
                                  ],
                                ),
                                if (question.explanation.isNotEmpty)
                                  const SizedBox(height: AppSpacing.xs),
                              ],
                              if (question.explanation.isNotEmpty) ...[
                                Text(
                                  'Context & Meaning',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  question.explanation,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark ? AppColors.darkText : AppColors.lightText,
                                    height: 1.4,
                                  ),
                                  softWrap: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),

              // --- Bottom Action Button ---
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AppPrimaryButton(
                  label: !isAnswerSubmitted
                      ? 'Check Answer'
                      : (currentIndex < total - 1 ? 'Next Question' : 'Finish Quiz'),
                  icon: !isAnswerSubmitted
                      ? Icons.check_rounded
                      : (currentIndex < total - 1 ? Icons.arrow_forward_rounded : Icons.flag_rounded),
                  onPressed: selectedOption == null
                      ? null
                      : (!isAnswerSubmitted
                          ? quizCtrl.submitAnswer
                          : () async {
                              unawaited(_speechService?.stop());
                              if (currentIndex < total - 1) {
                                quizCtrl.nextQuestion();
                              } else {
                                final auth = AppAuthScope.maybeOf(context);
                                final uid = (auth != null && auth.isSignedIn) ? auth.user?.uid : null;
                                await quizCtrl.finishQuiz(uid: uid);
                                if (context.mounted) {
                                  context.pushReplacement('/quiz/result');
                                }
                              }
                            }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
