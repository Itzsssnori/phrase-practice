export 'quiz_attempt.dart';

/// Question model for practice quizzes.
class QuizQuestion {
  final String id;
  final String prompt;
  final String originalPhrase;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.originalPhrase,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

/// Result summary of a completed quiz session.
class QuizResult {
  final int totalQuestions;
  final int correctAnswers;
  final List<QuizQuestion> mistakeQuestions;

  const QuizResult({
    required this.totalQuestions,
    required this.correctAnswers,
    this.mistakeQuestions = const [],
  });

  double get scorePercentage =>
      totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;
}
