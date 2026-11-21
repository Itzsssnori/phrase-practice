import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/phrase.dart';
import '../models/quiz.dart';
import 'quiz_attempt_repository.dart';
import 'quiz_generator.dart';

/// Manages active quiz session lifecycle: question generation, selection state,
/// answer grading, results formulation, and optional background attempt persistence.
class QuizController extends ChangeNotifier {
  final QuizAttemptRepository _repository;
  final Random? _customRandom;

  List<QuizQuestion> _questions = const [];
  int _currentIndex = 0;
  final Map<int, int> _selectedOptions = {};
  bool _isAnswerSubmitted = false;
  QuizResult? _lastResult;

  String? _currentCategoryId;
  int _requestedCount = 5;
  QuizDirection _requestedDirection = QuizDirection.nativeToTarget;
  String _fixedNativeLanguageCode = 'en';
  String _fixedTargetLanguageCode = 'es';

  bool _isSavingAttempt = false;
  String? _saveAttemptError;
  bool _attemptSaved = false;
  int _savedAttemptVersion = 0;

  QuizController({
    QuizAttemptRepository? repository,
    Random? random,
  })  : _repository = repository ?? FirestoreQuizAttemptRepository(),
        _customRandom = random;

  // ─── Getters ──────────────────────────────────────────────────────────

  bool get hasActiveQuiz => _questions.isNotEmpty;
  List<QuizQuestion> get questions => _questions;
  int get currentIndex => _currentIndex;
  int get totalQuestions => _questions.length;
  QuizQuestion? get currentQuestion =>
      (_currentIndex >= 0 && _currentIndex < _questions.length) ? _questions[_currentIndex] : null;

  int? get currentSelectedOption => _selectedOptions[_currentIndex];
  bool get isAnswerSubmitted => _isAnswerSubmitted;
  QuizResult? get lastResult => _lastResult;

  String? get currentCategoryId => _currentCategoryId;
  int get requestedCount => _requestedCount;
  QuizDirection get requestedDirection => _requestedDirection;
  String get fixedNativeLanguageCode => _fixedNativeLanguageCode;
  String get fixedTargetLanguageCode => _fixedTargetLanguageCode;

  bool get isSavingAttempt => _isSavingAttempt;
  String? get saveAttemptError => _saveAttemptError;
  bool get attemptSaved => _attemptSaved;
  int get savedAttemptVersion => _savedAttemptVersion;

  // ─── Session Setup ────────────────────────────────────────────────────

  /// Starts a fresh quiz session, locking the active language pair for its duration.
  bool startQuiz({
    required List<Phrase> allPhrases,
    required String nativeLanguageCode,
    required String targetLanguageCode,
    String? categoryId,
    int questionCount = 5,
    QuizDirection direction = QuizDirection.nativeToTarget,
    Random? random,
    List<String>? specificPhraseIds,
  }) {
    final effectiveRandom = random ?? _customRandom;

    final generated = QuizGenerator.generateQuestions(
      allPhrases: allPhrases,
      nativeLanguageCode: nativeLanguageCode,
      targetLanguageCode: targetLanguageCode,
      categoryId: categoryId,
      questionCount: questionCount,
      direction: direction,
      random: effectiveRandom,
      specificPhraseIds: specificPhraseIds,
    );

    if (generated.isEmpty) {
      return false;
    }

    _questions = generated;
    _currentIndex = 0;
    _selectedOptions.clear();
    _isAnswerSubmitted = false;
    _lastResult = null;
    _saveAttemptError = null;
    _attemptSaved = false;

    _currentCategoryId = (categoryId == 'all') ? null : categoryId;
    _requestedCount = questionCount;
    _requestedDirection = direction;
    _fixedNativeLanguageCode = nativeLanguageCode;
    _fixedTargetLanguageCode = targetLanguageCode;

    notifyListeners();
    return true;
  }

  // ─── In-Quiz Progression ──────────────────────────────────────────────

  /// Records the option tapped by user. Ignored if answer is already locked.
  void selectOption(int optionIndex) {
    if (_isAnswerSubmitted) return;
    _selectedOptions[_currentIndex] = optionIndex;
    notifyListeners();
  }

  /// Locks in the chosen answer and displays constructive feedback.
  void submitAnswer() {
    if (_isAnswerSubmitted || currentSelectedOption == null) return;
    _isAnswerSubmitted = true;
    notifyListeners();
  }

  /// Advances to next question if available.
  void nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _isAnswerSubmitted = false;
      notifyListeners();
    }
  }

  /// Concludes the quiz round, compiles results, and saves attempt if user is signed in.
  Future<QuizResult> finishQuiz({String? uid}) async {
    int correctCount = 0;
    final mistakes = <QuizMistake>[];
    final answerRecords = <QuizAnswerRecord>[];

    for (var i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final chosenIndex = _selectedOptions[i];
      final isCorrect = (chosenIndex != null && chosenIndex == q.correctIndex);

      if (isCorrect) {
        correctCount++;
      } else {
        final chosenText = (chosenIndex != null && chosenIndex >= 0 && chosenIndex < q.options.length)
            ? q.options[chosenIndex]
            : 'No answer';
        mistakes.add(
          QuizMistake(
            question: q,
            selectedIndex: chosenIndex ?? -1,
            selectedAnswer: chosenText,
          ),
        );
      }

      answerRecords.add(
        QuizAnswerRecord(
          phraseId: q.phrase.id,
          wasCorrect: isCorrect,
        ),
      );
    }

    final result = QuizResult(
      totalQuestions: _questions.length,
      correctAnswers: correctCount,
      mistakes: mistakes,
      targetLanguageCode: _fixedTargetLanguageCode,
      categoryId: _currentCategoryId,
    );

    _lastResult = result;
    _questions = const [];
    _currentIndex = 0;
    _selectedOptions.clear();
    _isAnswerSubmitted = false;

    // Save attempt if signed-in user provided
    if (uid != null && uid.isNotEmpty) {
      await _persistAttempt(uid, result, answerRecords);
    }

    notifyListeners();
    return result;
  }

  Future<void> _persistAttempt(
    String uid,
    QuizResult result,
    List<QuizAnswerRecord> answerRecords,
  ) async {
    _isSavingAttempt = true;
    _saveAttemptError = null;
    notifyListeners();

    final attempt = QuizAttempt(
      id: '',
      targetLanguageCode: result.targetLanguageCode,
      categoryId: result.categoryId,
      score: result.correctAnswers,
      total: result.totalQuestions,
      takenAt: DateTime.now(),
      answers: answerRecords,
    );

    final saveRes = await _repository.saveAttempt(uid, attempt);
    _isSavingAttempt = false;

    if (saveRes.isSuccess) {
      _attemptSaved = true;
      _saveAttemptError = null;
      _savedAttemptVersion++;
    } else {
      _saveAttemptError = saveRes.errorMessageOrNull ?? 'Failed to save quiz attempt.';
    }

    notifyListeners();
  }

  /// Retries saving the last result for signed-in user.
  Future<void> retrySaveAttempt(String uid) async {
    if (_lastResult == null || _attemptSaved) return;

    final answerRecords = <QuizAnswerRecord>[];
    // If original questions list was cleared, we reconstruct records from mistakes
    for (final m in _lastResult!.mistakes) {
      answerRecords.add(QuizAnswerRecord(phraseId: m.phrase.id, wasCorrect: false));
    }
    final remainingCorrect = _lastResult!.correctAnswers;
    for (var i = 0; i < remainingCorrect; i++) {
      answerRecords.add(QuizAnswerRecord(phraseId: 'correct_$i', wasCorrect: true));
    }

    await _persistAttempt(uid, _lastResult!, answerRecords);
  }

  /// Restarts quiz with identical settings and a fresh shuffle.
  bool restartQuiz(List<Phrase> allPhrases) {
    return startQuiz(
      allPhrases: allPhrases,
      nativeLanguageCode: _fixedNativeLanguageCode,
      targetLanguageCode: _fixedTargetLanguageCode,
      categoryId: _currentCategoryId,
      questionCount: _requestedCount,
      direction: _requestedDirection,
    );
  }

  /// Starts a new quiz using only the phrases that were answered incorrectly.
  bool practiceMistakes(List<Phrase> allPhrases) {
    if (_lastResult == null || _lastResult!.mistakes.isEmpty) return false;

    final mistakeIds = _lastResult!.mistakes.map((m) => m.phrase.id).toList();

    return startQuiz(
      allPhrases: allPhrases,
      nativeLanguageCode: _fixedNativeLanguageCode,
      targetLanguageCode: _fixedTargetLanguageCode,
      categoryId: null, // pool can draw distractors from all categories
      questionCount: mistakeIds.length,
      direction: _requestedDirection,
      specificPhraseIds: mistakeIds,
    );
  }

  /// Discards active quiz session without saving.
  void discardQuiz() {
    _questions = const [];
    _currentIndex = 0;
    _selectedOptions.clear();
    _isAnswerSubmitted = false;
    notifyListeners();
  }

  /// Clears all in-memory quiz state (active session and last result), e.g. on sign-out or account deletion.
  void clear() {
    _questions = const [];
    _currentIndex = 0;
    _selectedOptions.clear();
    _isAnswerSubmitted = false;
    _lastResult = null;
    _currentCategoryId = null;
    _isSavingAttempt = false;
    _saveAttemptError = null;
    _attemptSaved = false;
    notifyListeners();
  }
}
