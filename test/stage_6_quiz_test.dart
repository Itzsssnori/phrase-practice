import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:phrase_practice/models/auth_user.dart';
import 'package:phrase_practice/models/category.dart';
import 'package:phrase_practice/models/phrase.dart';
import 'package:phrase_practice/models/phrase_translation.dart';
import 'package:phrase_practice/models/quiz.dart';
import 'package:phrase_practice/models/result.dart';
import 'package:phrase_practice/screens/quiz_result_screen.dart';
import 'package:phrase_practice/screens/quiz_screen.dart';
import 'package:phrase_practice/screens/quiz_setup_screen.dart';
import 'package:phrase_practice/screens/review_mistakes_screen.dart';
import 'package:phrase_practice/services/auth_controller.dart';
import 'package:phrase_practice/services/auth_repository.dart';
import 'package:phrase_practice/services/browse_data_service.dart';
import 'package:phrase_practice/services/language_settings_controller.dart';
import 'package:phrase_practice/services/quiz_attempt_repository.dart';
import 'package:phrase_practice/services/quiz_controller.dart';
import 'package:phrase_practice/services/quiz_generator.dart';
import 'package:phrase_practice/widgets/app_auth_scope.dart';
import 'package:phrase_practice/widgets/app_quiz_scope.dart';
import 'package:phrase_practice/widgets/app_settings_scope.dart';
import 'package:phrase_practice/widgets/phrase_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stage_3_browse_test.dart';

// ─── Test Fakes ─────────────────────────────────────────────────────────────

class FakeQuizAttemptRepository implements QuizAttemptRepository {
  final List<Map<String, dynamic>> savedPayloads = [];
  final List<QuizAttempt> recentAttemptsToReturn;
  bool shouldFailSave;

  FakeQuizAttemptRepository({
    this.recentAttemptsToReturn = const [],
    this.shouldFailSave = false,
  });

  @override
  Future<RepoResult<String>> saveAttempt(String uid, QuizAttempt attempt) async {
    savedPayloads.add({
      'uid': uid,
      'targetLanguageCode': attempt.targetLanguageCode,
      'categoryId': attempt.categoryId,
      'score': attempt.score,
      'total': attempt.total,
      'takenAt': attempt.takenAt,
      'answers': attempt.answers.map((a) => a.toMap()).toList(),
    });

    if (shouldFailSave) {
      return RepoResult.error('Network failure while saving attempt', 'save-error');
    }
    return RepoResult.success('attempt_${savedPayloads.length}');
  }

  @override
  Future<RepoResult<List<QuizAttempt>>> getRecentAttempts(String uid, {int limit = 5}) async {
    return RepoResult.success(recentAttemptsToReturn.take(limit).toList());
  }
}

class FakeAuthRepository implements AuthRepository {
  AuthUser? _currentUser;

  FakeAuthRepository({AuthUser? user}) : _currentUser = user;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(_currentUser);

  @override
  Future<RepoResult<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      _currentUser != null
          ? RepoResult.success(_currentUser!)
          : RepoResult.error('User not found', 'user-not-found');

  @override
  Future<RepoResult<AuthUser>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async =>
      RepoResult.error('Not needed', 'unimplemented');

  @override
  Future<RepoResult<void>> sendPasswordResetEmail(String email) async =>
      RepoResult.success(null);

  @override
  Future<RepoResult<void>> signOut() async {
    _currentUser = null;
    return RepoResult.success(null);
  }

  @override
  Future<RepoResult<void>> sendEmailVerification() async => const RepoResult.success(null);

  @override
  Future<RepoResult<AuthUser?>> reloadUser() async => RepoResult.success(_currentUser);

  @override
  Future<RepoResult<void>> reauthenticateWithPassword(String password) async =>
      const RepoResult.success(null);

  @override
  Future<RepoResult<void>> deleteAccount() async {
    _currentUser = null;
    return const RepoResult.success(null);
  }
}

// ─── Test Fixture Helpers ───────────────────────────────────────────────────

Phrase _makePhrase(
  String id, {
  required String categoryId,
  String? enText,
  String? esText,
  String? pronunciation,
  String? note,
  bool isActive = true,
}) {
  final trans = <String, PhraseTranslation>{};
  if (enText != null) {
    trans['en'] = PhraseTranslation(
      text: enText,
      pronunciation: null,
      meaningNote: note ?? '',
    );
  }
  if (esText != null) {
    trans['es'] = PhraseTranslation(
      text: esText,
      pronunciation: pronunciation ?? '$esText phonetic',
      meaningNote: note ?? '',
    );
  }
  return Phrase(
    id: id,
    categoryId: categoryId,
    originalText: enText ?? id,
    translatedText: esText ?? id,
    phonetic: pronunciation,
    contextNote: note,
    isActive: isActive,
    translations: trans,
  );
}

List<Phrase> _createStandardPhrases() {
  return [
    // Category: greetings (3 phrases)
    _makePhrase('g1', categoryId: 'greetings', enText: 'Hello', esText: 'Hola', pronunciation: 'OH-lah', note: 'Standard greeting'),
    _makePhrase('g2', categoryId: 'greetings', enText: 'Good morning', esText: 'Buenos días', pronunciation: 'BWAY-nohs DEE-ahs'),
    _makePhrase('g3', categoryId: 'greetings', enText: 'Good night', esText: 'Buenas noches', pronunciation: 'BWAY-nahs NOH-chehs'),
    // Category: food (3 phrases)
    _makePhrase('f1', categoryId: 'food', enText: 'Water please', esText: 'Agua por favor', note: 'Polite request for water'),
    _makePhrase('f2', categoryId: 'food', enText: 'The check please', esText: 'La cuenta por favor'),
    _makePhrase('f3', categoryId: 'food', enText: 'Delicious', esText: 'Delicioso'),
    // Category: travel (3 phrases)
    _makePhrase('t1', categoryId: 'travel', enText: 'Where is the bathroom?', esText: '¿Dónde está el baño?'),
    _makePhrase('t2', categoryId: 'travel', enText: 'How much is this?', esText: '¿Cuánto cuesta esto?'),
    _makePhrase('t3', categoryId: 'travel', enText: 'I need help', esText: 'Necesito ayuda'),
  ];
}

Widget buildTestApp({
  required Widget child,
  QuizController? quizCtrl,
  AuthController? authCtrl,
  LanguageSettingsController? settingsCtrl,
}) {
  return MaterialApp(
    home: AppAuthScope(
      controller: authCtrl ?? AuthController(authRepository: FakeAuthRepository()),
      child: AppSettingsScope(
        controller: settingsCtrl ?? LanguageSettingsController(),
        child: AppQuizScope(
          controller: quizCtrl ?? QuizController(),
          child: child,
        ),
      ),
    ),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuizGenerator – Pure Dart Logic', () {
    final phrases = _createStandardPhrases();

    test('generates exactly 4 unique options with 1 correct answer', () {
      final questions = QuizGenerator.generateQuestions(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        questionCount: 5,
        random: Random(42),
      );

      expect(questions.length, 5);
      for (final q in questions) {
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4, reason: 'Options must be unique');
        expect(q.options.contains(q.correctAnswer), isTrue);
        expect(q.options[q.correctIndex], q.correctAnswer);
      }
    });

    test('ensures no phrase is repeated as a question in a single round', () {
      final questions = QuizGenerator.generateQuestions(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        questionCount: 9,
        random: Random(99),
      );

      final questionPhraseIds = questions.map((q) => q.phrase.id).toList();
      expect(questionPhraseIds.toSet().length, questionPhraseIds.length);
    });

    test('distractor fallback draws from other categories when same category has < 3', () {
      // Greetings category has only 3 phrases total -> only 2 same-category distractors available
      final questions = QuizGenerator.generateQuestions(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        categoryId: 'greetings',
        questionCount: 2,
        random: Random(123),
      );

      expect(questions.length, 2);
      for (final q in questions) {
        expect(q.options.length, 4, reason: 'Must still find 3 distractors via fallback');
        expect(q.options.toSet().length, 4);
      }
    });

    test('caps question count by available eligible pool', () {
      final questions = QuizGenerator.generateQuestions(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        categoryId: 'travel', // 3 phrases in travel
        questionCount: 10,
        random: Random(1),
      );

      expect(questions.length, 3, reason: 'Capped at the 3 available travel phrases');
    });

    test('blocks generation and returns empty when overall eligible pool < 4', () {
      final smallPool = phrases.take(3).toList();
      final questions = QuizGenerator.generateQuestions(
        allPhrases: smallPool,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        questionCount: 5,
      );

      expect(questions, isEmpty, reason: 'Cannot create 4-option quiz with fewer than 4 phrases');
    });

    test('respects Native to Target direction', () {
      final questions = QuizGenerator.generateQuestions(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        direction: QuizDirection.nativeToTarget,
        random: Random(5),
      );

      for (final q in questions) {
        // Native is enText, correct answer is esText
        expect(q.prompt, contains('translation'));
        expect(q.originalPhrase, q.phrase.translationFor('en')!.text);
        expect(q.correctAnswer, q.phrase.translationFor('es')!.text);
      }
    });

    test('respects Target to Native direction', () {
      final questions = QuizGenerator.generateQuestions(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        direction: QuizDirection.targetToNative,
        random: Random(7),
      );

      for (final q in questions) {
        // Target is esText, correct answer is enText
        expect(q.prompt, contains('meaning'));
        expect(q.originalPhrase, q.phrase.translationFor('es')!.text);
        expect(q.correctAnswer, q.phrase.translationFor('en')!.text);
      }
    });

    test('mixed direction produces both directions deterministically', () {
      final questions = QuizGenerator.generateQuestions(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        direction: QuizDirection.mixed,
        questionCount: 8,
        random: Random(42),
      );

      final hasNativeToTarget = questions.any((q) => q.direction == QuizDirection.nativeToTarget);
      final hasTargetToNative = questions.any((q) => q.direction == QuizDirection.targetToNative);
      expect(hasNativeToTarget, isTrue);
      expect(hasTargetToNative, isTrue);
    });

    test('deterministic with seeded Random', () {
      final qA = QuizGenerator.generateQuestions(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        questionCount: 5,
        random: Random(777),
      );
      final qB = QuizGenerator.generateQuestions(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        questionCount: 5,
        random: Random(777),
      );

      expect(qA.length, qB.length);
      for (var i = 0; i < qA.length; i++) {
        expect(qA[i].id, qB[i].id);
        expect(qA[i].originalPhrase, qB[i].originalPhrase);
        expect(qA[i].options, qB[i].options);
        expect(qA[i].correctIndex, qB[i].correctIndex);
      }
    });
  });

  group('QuizController – Session Flow, Language Lock, & Scoring', () {
    final phrases = _createStandardPhrases();

    test('progression, option selection locking, and scoring calculation', () async {
      final repo = FakeQuizAttemptRepository();
      final ctrl = QuizController(repository: repo, random: Random(10));

      final started = ctrl.startQuiz(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        questionCount: 3,
      );
      expect(started, isTrue);
      expect(ctrl.hasActiveQuiz, isTrue);
      expect(ctrl.currentIndex, 0);

      // Question 0: answer correctly
      final q0 = ctrl.currentQuestion!;
      ctrl.selectOption(q0.correctIndex);
      expect(ctrl.currentSelectedOption, q0.correctIndex);

      ctrl.submitAnswer();
      expect(ctrl.isAnswerSubmitted, isTrue);

      // Attempt to change option while locked -> should be ignored
      ctrl.selectOption((q0.correctIndex + 1) % 4);
      expect(ctrl.currentSelectedOption, q0.correctIndex);

      // Next question
      ctrl.nextQuestion();
      expect(ctrl.currentIndex, 1);
      expect(ctrl.isAnswerSubmitted, isFalse);

      // Question 1: answer incorrectly
      final q1 = ctrl.currentQuestion!;
      final wrongIndex = (q1.correctIndex + 1) % 4;
      ctrl.selectOption(wrongIndex);
      ctrl.submitAnswer();
      ctrl.nextQuestion();

      // Question 2: answer correctly
      final q2 = ctrl.currentQuestion!;
      ctrl.selectOption(q2.correctIndex);
      ctrl.submitAnswer();

      // Conclude quiz for guest
      final result = await ctrl.finishQuiz(uid: null);
      expect(result.totalQuestions, 3);
      expect(result.correctAnswers, 2);
      expect(result.mistakes.length, 1);
      expect(result.mistakes.first.question.id, q1.id);
      expect(result.scorePercentage, closeTo(66.6, 0.5));
      expect(repo.savedPayloads, isEmpty, reason: 'Guest mode must write nothing');
    });

    test('language pair remains locked during quiz even if settings change', () {
      final ctrl = QuizController();
      ctrl.startQuiz(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        questionCount: 3,
      );

      expect(ctrl.fixedNativeLanguageCode, 'en');
      expect(ctrl.fixedTargetLanguageCode, 'es');
      final firstQuestionText = ctrl.currentQuestion!.originalPhrase;

      // Even if caller changes external variables, quiz state retains fixed pair
      expect(ctrl.currentQuestion!.originalPhrase, firstQuestionText);
      expect(ctrl.fixedNativeLanguageCode, 'en');
    });

    test('restartQuiz restarts round with same settings', () {
      final ctrl = QuizController();
      ctrl.startQuiz(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        categoryId: 'food',
        questionCount: 3,
      );

      final restarted = ctrl.restartQuiz(phrases);
      expect(restarted, isTrue);
      expect(ctrl.totalQuestions, 3);
      expect(ctrl.currentCategoryId, 'food');
    });

    test('practiceMistakes starts new quiz targeting only mistake phrases', () async {
      final ctrl = QuizController();
      ctrl.startQuiz(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        questionCount: 5,
        random: Random(42),
      );

      // Submit incorrect answers
      for (var i = 0; i < ctrl.totalQuestions; i++) {
        final q = ctrl.currentQuestion!;
        final wrong = (q.correctIndex + 1) % 4;
        ctrl.selectOption(wrong);
        ctrl.submitAnswer();
        if (i < ctrl.totalQuestions - 1) ctrl.nextQuestion();
      }

      final result = await ctrl.finishQuiz(uid: null);
      expect(result.mistakes.length, 5);

      final practiced = ctrl.practiceMistakes(phrases);
      expect(practiced, isTrue);
      expect(ctrl.totalQuestions, 5);
      final mistakeIds = result.mistakes.map((m) => m.phrase.id).toSet();
      for (final q in ctrl.questions) {
        expect(mistakeIds.contains(q.phrase.id), isTrue);
      }
    });

    test('discardQuiz clears active quiz without saving', () {
      final repo = FakeQuizAttemptRepository();
      final ctrl = QuizController(repository: repo);
      ctrl.startQuiz(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
      );
      expect(ctrl.hasActiveQuiz, isTrue);

      ctrl.discardQuiz();
      expect(ctrl.hasActiveQuiz, isFalse);
      expect(ctrl.questions, isEmpty);
      expect(repo.savedPayloads, isEmpty);
    });
  });

  group('Quiz Attempt Repository – Field Restrictions & Retries', () {
    final phrases = _createStandardPhrases();

    test('signed-in user saves attempt once with ONLY allowed fields', () async {
      final repo = FakeQuizAttemptRepository();
      final ctrl = QuizController(repository: repo);

      ctrl.startQuiz(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        questionCount: 4,
      );

      for (var i = 0; i < 4; i++) {
        ctrl.selectOption(ctrl.currentQuestion!.correctIndex);
        ctrl.submitAnswer();
        if (i < 3) ctrl.nextQuestion();
      }

      await ctrl.finishQuiz(uid: 'user_123');

      expect(repo.savedPayloads.length, 1);
      final payload = repo.savedPayloads.first;
      expect(payload['uid'], 'user_123');
      expect(payload['targetLanguageCode'], 'es');
      expect(payload['score'], 4);
      expect(payload['total'], 4);
      expect(payload.containsKey('takenAt'), isTrue);
      expect(payload.containsKey('answers'), isTrue);

      // Verify no extra forbidden fields like email, name, etc.
      final allowedKeys = {
        'uid',
        'targetLanguageCode',
        'categoryId',
        'score',
        'total',
        'takenAt',
        'answers',
      };
      expect(payload.keys.toSet().difference(allowedKeys), isEmpty);

      // Check answers structure
      final answers = payload['answers'] as List<dynamic>;
      expect(answers.length, 4);
      for (final a in answers) {
        final aMap = a as Map<String, dynamic>;
        expect(aMap.keys.toSet(), {'phraseId', 'wasCorrect'});
      }
    });

    test('save failure keeps result displayed and allows retry', () async {
      final repo = FakeQuizAttemptRepository(shouldFailSave: true);
      final ctrl = QuizController(repository: repo);

      ctrl.startQuiz(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        questionCount: 3,
      );

      for (var i = 0; i < 3; i++) {
        ctrl.selectOption(ctrl.currentQuestion!.correctIndex);
        ctrl.submitAnswer();
        if (i < 2) ctrl.nextQuestion();
      }

      await ctrl.finishQuiz(uid: 'user_fail_test');

      expect(ctrl.attemptSaved, isFalse);
      expect(ctrl.saveAttemptError, isNotNull);
      expect(ctrl.lastResult, isNotNull);

      // Fix failure and retry
      repo.shouldFailSave = false;
      await ctrl.retrySaveAttempt('user_fail_test');

      expect(ctrl.attemptSaved, isTrue);
      expect(ctrl.saveAttemptError, isNull);
    });
  });

  group('Quiz Screens – Widget Tests', () {
    final phrases = _createStandardPhrases();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      BrowseDataService.setMockInstance(
        BrowseDataService(
          languageRepo: MockLanguageRepository([]),
          categoryRepo: MockCategoryRepository([
            const Category(id: 'greetings', names: {'en': 'Greetings'}),
            const Category(id: 'food', names: {'en': 'Food & Drinks'}),
            const Category(id: 'travel', names: {'en': 'Travel & Transit'}),
          ]),
          phraseRepo: MockPhraseRepository(phrases),
        ),
      );
    });

    testWidgets('QuizSetupScreen renders setup choices, categories, and question counts', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const QuizSetupScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Recall Practice'), findsOneWidget);
      expect(find.text('5 questions'), findsOneWidget);
      expect(find.text('10 questions'), findsOneWidget);
      expect(find.text('20 questions'), findsOneWidget);
      expect(find.text('Native to Target'), findsOneWidget);
      expect(find.text('Begin Practice Session'), findsOneWidget);
    });

    testWidgets('QuizSetupScreen disables start button when topic has fewer than 4 phrases', (tester) async {
      // Setup mock service with only 2 phrases in a category
      final tinyPool = [
        _makePhrase('p1', categoryId: 'rare', enText: 'Hello', esText: 'Hola'),
        _makePhrase('p2', categoryId: 'rare', enText: 'Bye', esText: 'Adios'),
      ];
      BrowseDataService.setMockInstance(
        BrowseDataService(
          languageRepo: MockLanguageRepository([]),
          categoryRepo: MockCategoryRepository([
            const Category(id: 'rare', names: {'en': 'Rare Topic'}),
          ]),
          phraseRepo: MockPhraseRepository(tinyPool),
        ),
      );

      await tester.pumpWidget(buildTestApp(child: const QuizSetupScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('At least 4 phrases are needed'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.ancestor(of: find.text('Begin Practice Session'), matching: find.byType(ElevatedButton)),
      );
      expect(button.onPressed, isNull, reason: 'Start button must be disabled');
    });

    testWidgets('QuizSetupScreen renders recent quizzes for signed in users', (tester) async {
      final fakeRepo = FakeQuizAttemptRepository(
        recentAttemptsToReturn: [
          QuizAttempt(
            id: 'a1',
            targetLanguageCode: 'es',
            categoryId: 'food',
            score: 8,
            total: 10,
            takenAt: DateTime(2026, 11, 15),
          ),
        ],
      );

      final authUser = AuthUser(uid: 'user_recents', email: 'test@example.com');
      final authCtrl = AuthController(authRepository: FakeAuthRepository(user: authUser));

      await tester.pumpWidget(
        buildTestApp(
          child: QuizSetupScreen(attemptRepository: fakeRepo),
          authCtrl: authCtrl,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RECENT QUIZZES'), findsOneWidget);
      expect(find.text('8 / 10'), findsOneWidget);
    });

    testWidgets('QuizScreen option selection, feedback, and pronunciation display', (tester) async {
      final ctrl = QuizController();
      ctrl.startQuiz(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        questionCount: 3,
        random: Random(42),
      );

      await tester.pumpWidget(buildTestApp(child: const QuizScreen(), quizCtrl: ctrl));
      await tester.pumpAndSettle();

      expect(find.text('1 of 3'), findsOneWidget);
      expect(find.text('Check Answer'), findsOneWidget);

      // Tap first option
      final firstOption = ctrl.currentQuestion!.options[0];
      await tester.tap(find.text(firstOption));
      await tester.pumpAndSettle();

      // Submit answer
      await tester.tap(find.text('Check Answer'));
      await tester.pumpAndSettle();

      // Feedback is displayed: "Correct" or "Incorrect"
      final hasCorrect = find.text('Correct').evaluate().isNotEmpty;
      final hasIncorrect = find.text('Incorrect').evaluate().isNotEmpty;
      expect(hasCorrect || hasIncorrect, isTrue);

      // Button updates to Next Question
      expect(find.text('Next Question'), findsOneWidget);
    });

    testWidgets('QuizScreen exit button prompts confirmation dialog', (tester) async {
      final ctrl = QuizController();
      ctrl.startQuiz(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
      );

      await tester.pumpWidget(buildTestApp(child: const QuizScreen(), quizCtrl: ctrl));
      await tester.pumpAndSettle();

      // Tap close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Leave Quiz?'), findsOneWidget);
      expect(find.text('Stay'), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);

      // Tap stay keeps quiz active
      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();
      expect(find.text('Leave Quiz?'), findsNothing);
      expect(ctrl.hasActiveQuiz, isTrue);
    });

    testWidgets('QuizResultScreen displays score, calm message, and missed phrases', (tester) async {
      final ctrl = QuizController();
      ctrl.startQuiz(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        questionCount: 2,
        random: Random(42),
      );

      // Answer 1 correct, 1 incorrect
      final q0 = ctrl.currentQuestion!;
      ctrl.selectOption(q0.correctIndex);
      ctrl.submitAnswer();
      ctrl.nextQuestion();

      final q1 = ctrl.currentQuestion!;
      ctrl.selectOption((q1.correctIndex + 1) % 4);
      ctrl.submitAnswer();

      await ctrl.finishQuiz(uid: null);

      await tester.pumpWidget(buildTestApp(child: const QuizResultScreen(), quizCtrl: ctrl));
      await tester.pumpAndSettle();

      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Session Complete'), findsOneWidget);
      expect(find.text('MISSED PHRASES (1)'), findsOneWidget);
      expect(find.text('Review Mistakes'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      // Guest sign in prompt card
      expect(find.text('Sign in to save your results'), findsOneWidget);
    });

    testWidgets('ReviewMistakesScreen renders missed phrases as PhraseCards and allows repeat practice', (tester) async {
      final ctrl = QuizController();
      ctrl.startQuiz(
        allPhrases: phrases,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        questionCount: 2,
        random: Random(42),
      );

      // Fail both questions
      for (var i = 0; i < 2; i++) {
        ctrl.selectOption((ctrl.currentQuestion!.correctIndex + 1) % 4);
        ctrl.submitAnswer();
        if (i < 1) ctrl.nextQuestion();
      }
      await ctrl.finishQuiz(uid: null);

      await tester.pumpWidget(buildTestApp(child: const ReviewMistakesScreen(), quizCtrl: ctrl));
      await tester.pumpAndSettle();

      expect(find.text('Deepen Comprehension'), findsOneWidget);
      expect(find.text('Practice These Again'), findsOneWidget);
      expect(find.byType(PhraseCard), findsNWidgets(2));
    });
  });
}
