/// Summary data model representing user study metrics and progress.
class UserProgress {
  final int phrasesLearned;
  final int totalPhrases;
  final int currentStreakDays;
  final int totalQuizzesTaken;
  final double averageAccuracy;

  const UserProgress({
    required this.phrasesLearned,
    required this.totalPhrases,
    required this.currentStreakDays,
    required this.totalQuizzesTaken,
    required this.averageAccuracy,
  });

  double get completionRatio =>
      totalPhrases > 0 ? (phrasesLearned / totalPhrases).clamp(0.0, 1.0) : 0.0;
}
