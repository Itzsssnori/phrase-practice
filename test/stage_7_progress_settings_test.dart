import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:phrase_practice/content/privacy_copy.dart';
import 'package:phrase_practice/models/auth_user.dart';
import 'package:phrase_practice/models/category.dart';
import 'package:phrase_practice/models/language.dart';
import 'package:phrase_practice/models/phrase.dart';
import 'package:phrase_practice/models/phrase_translation.dart';
import 'package:phrase_practice/models/quiz_attempt.dart';
import 'package:phrase_practice/models/result.dart';
import 'package:phrase_practice/models/user_profile.dart';
import 'package:phrase_practice/screens/privacy_screen.dart';
import 'package:phrase_practice/screens/profile_screen.dart';
import 'package:phrase_practice/screens/progress_screen.dart';
import 'package:phrase_practice/services/auth_controller.dart';
import 'package:phrase_practice/services/auth_repository.dart';
import 'package:phrase_practice/services/browse_data_service.dart';
import 'package:phrase_practice/services/language_settings_controller.dart';
import 'package:phrase_practice/services/profile_repository.dart';
import 'package:phrase_practice/services/progress_calculator.dart';
import 'package:phrase_practice/services/progress_controller.dart';
import 'package:phrase_practice/services/quiz_attempt_repository.dart';
import 'package:phrase_practice/services/quiz_controller.dart';
import 'package:phrase_practice/services/user_phrase_controller.dart';
import 'package:phrase_practice/services/user_phrase_repository.dart';
import 'package:phrase_practice/theme/app_theme.dart';
import 'package:phrase_practice/widgets/app_auth_scope.dart';
import 'package:phrase_practice/widgets/app_progress_scope.dart';
import 'package:phrase_practice/widgets/app_settings_scope.dart';
import 'package:phrase_practice/widgets/app_user_phrase_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stage_3_browse_test.dart';

// ─── Fake Repositories ───────────────────────────────────────────────────────

class _FakeAuthRepo implements AuthRepository {
  final StreamController<AuthUser?> _stream = StreamController<AuthUser?>.broadcast();
  AuthUser? _current;
  final List<String> callLog = [];

  bool reauthShouldFail = false;
  bool deleteAuthShouldFail = false;
  bool sendVerificationShouldFail = false;
  AuthUser? reloadedUserOverride;

  _FakeAuthRepo({AuthUser? initialUser}) : _current = initialUser;

  void emitUser(AuthUser? user) {
    _current = user;
    _stream.add(user);
  }

  @override
  Stream<AuthUser?> get authStateChanges => _stream.stream;

  @override
  AuthUser? get currentUser => _current;

  @override
  Future<RepoResult<AuthUser>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final user = AuthUser(uid: 'u1', email: email, displayName: displayName);
    emitUser(user);
    return RepoResult.success(user);
  }

  @override
  Future<RepoResult<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final user = AuthUser(uid: 'u1', email: email, displayName: 'Learner');
    emitUser(user);
    return RepoResult.success(user);
  }

  @override
  Future<RepoResult<void>> sendPasswordResetEmail(String email) async =>
      const RepoResult.success(null);

  @override
  Future<RepoResult<void>> signOut() async {
    callLog.add('signOut');
    emitUser(null);
    return const RepoResult.success(null);
  }

  @override
  Future<RepoResult<void>> sendEmailVerification() async {
    callLog.add('sendEmailVerification');
    if (sendVerificationShouldFail) {
      return const RepoResult.error('Too many requests. Please try again later.');
    }
    return const RepoResult.success(null);
  }

  @override
  Future<RepoResult<AuthUser?>> reloadUser() async {
    callLog.add('reloadUser');
    if (reloadedUserOverride != null) {
      _current = reloadedUserOverride;
    }
    return RepoResult.success(_current);
  }

  @override
  Future<RepoResult<void>> reauthenticateWithPassword(String password) async {
    callLog.add('reauth');
    if (reauthShouldFail) {
      return const RepoResult.error('Incorrect email or password.');
    }
    return const RepoResult.success(null);
  }

  @override
  Future<RepoResult<void>> deleteAccount() async {
    callLog.add('deleteAuthUser');
    if (deleteAuthShouldFail) {
      return const RepoResult.error('Could not delete your account right now.');
    }
    emitUser(null);
    return const RepoResult.success(null);
  }

  void dispose() => _stream.close();
}

class _FakeProfileRepo implements ProfileRepository {
  final Map<String, UserProfile> profiles = {};
  final List<String> callLog;
  final List<Map<String, dynamic>> displayNamePayloads = [];
  int createProfileCallCount = 0;
  int updateLanguagesCallCount = 0;
  bool updateDisplayNameShouldFail = false;
  bool deleteDataShouldFail = false;

  _FakeProfileRepo({List<String>? sharedCallLog}) : callLog = sharedCallLog ?? [];

  @override
  Future<RepoResult<UserProfile>> getUserProfile(String uid) async {
    final p = profiles[uid];
    if (p == null) return RepoResult.empty('Not found');
    return RepoResult.success(p);
  }

  @override
  Future<RepoResult<void>> updateDisplayName(String uid, String displayName) async {
    callLog.add('updateDisplayName');
    if (updateDisplayNameShouldFail) {
      return const RepoResult.error('Could not update your display name. Please try again.');
    }
    displayNamePayloads.add({'displayName': displayName.trim()});
    final existing = profiles[uid];
    if (existing != null) {
      profiles[uid] = existing.copyWith(displayName: displayName.trim());
    }
    return const RepoResult.success(null);
  }

  @override
  Future<RepoResult<void>> updateUserLanguages(
    String uid, {
    required String nativeLanguageCode,
    required String targetLanguageCode,
  }) async {
    updateLanguagesCallCount++;
    return const RepoResult.success(null);
  }

  @override
  Future<RepoResult<void>> updateUserPreferences(
    String uid,
    Map<String, dynamic> preferences,
  ) async =>
      const RepoResult.success(null);

  @override
  Future<RepoResult<UserProfile>> createProfile({
    required String uid,
    String? displayName,
    required String nativeLanguageCode,
    required String targetLanguageCode,
  }) async {
    createProfileCallCount++;
    callLog.add('createProfile');
    final profile = UserProfile(
      uid: uid,
      displayName: displayName,
      nativeLanguageCode: nativeLanguageCode,
      targetLanguageCode: targetLanguageCode,
      preferences: const {},
      createdAt: DateTime.now(),
    );
    profiles[uid] = profile;
    return RepoResult.success(profile);
  }

  @override
  Future<RepoResult<void>> createOrUpdateProfile(UserProfile profile) async {
    profiles[profile.uid] = profile;
    return const RepoResult.success(null);
  }

  @override
  Future<RepoResult<void>> deleteUserData(String uid) async {
    if (deleteDataShouldFail) {
      callLog.add('deleteUserData:failed');
      return const RepoResult.error('Could not delete all of your saved data.');
    }
    for (final sub in ProfileRepository.userSubcollections) {
      callLog.add('deleteSubcollection:$sub');
    }
    profiles.remove(uid);
    callLog.add('deleteProfileDoc:$uid');
    return const RepoResult.success(null);
  }
}

class _FakeQuizAttemptRepo implements QuizAttemptRepository {
  List<QuizAttempt> attempts = [];
  int getCalls = 0;
  int? lastRequestedLimit;
  bool shouldFailLoad = false;

  @override
  Future<RepoResult<String>> saveAttempt(String uid, QuizAttempt attempt) async {
    attempts.insert(0, attempt);
    return RepoResult.success('attempt_${attempts.length}');
  }

  @override
  Future<RepoResult<List<QuizAttempt>>> getRecentAttempts(String uid, {int limit = 5}) async {
    getCalls++;
    lastRequestedLimit = limit;
    if (shouldFailLoad) {
      return const RepoResult.error('Network error loading attempts.');
    }
    return RepoResult.success(attempts.take(limit).toList());
  }
}

class _FakeUserPhraseRepo implements UserPhraseRepository {
  List<String> favorites = [];
  Map<String, Set<String>> learnedByLang = {};
  List<String> recents = [];

  @override
  Future<RepoResult<List<String>>> getFavoritePhraseIds(String uid) async =>
      RepoResult.success(List<String>.from(favorites));

  @override
  Future<RepoResult<void>> addFavorite(String uid, String phraseSlug) async =>
      const RepoResult.success(null);

  @override
  Future<RepoResult<void>> removeFavorite(String uid, String phraseSlug) async =>
      const RepoResult.success(null);

  @override
  Future<RepoResult<Map<String, Set<String>>>> getAllLearnedPhraseIds(String uid) async =>
      RepoResult.success({
        for (final e in learnedByLang.entries) e.key: Set<String>.from(e.value),
      });

  @override
  Future<RepoResult<void>> markPhraseLearned(
    String uid,
    String phraseSlug,
    String targetLanguageCode,
  ) async =>
      const RepoResult.success(null);

  @override
  Future<RepoResult<void>> unmarkPhraseLearned(
    String uid,
    String phraseSlug,
    String targetLanguageCode,
  ) async =>
      const RepoResult.success(null);

  @override
  Future<RepoResult<List<String>>> getRecentPhraseIds(String uid, {int limit = 20}) async =>
      RepoResult.success(recents.take(limit).toList());

  @override
  Future<RepoResult<void>> recordRecentView(String uid, String phraseSlug) async =>
      const RepoResult.success(null);
}

// ─── Fixture Helpers ─────────────────────────────────────────────────────────

Phrase _phrase(
  String id, {
  required String categoryId,
  String? en,
  String? es,
  String? fil,
  bool isActive = true,
}) {
  return Phrase(
    id: id,
    categoryId: categoryId,
    originalText: en ?? '',
    translatedText: es ?? '',
    isActive: isActive,
    translations: {
      if (en != null) 'en': PhraseTranslation(text: en),
      if (es != null) 'es': PhraseTranslation(text: es),
      if (fil != null) 'fil': PhraseTranslation(text: fil),
    },
  );
}

QuizAttempt _attempt(int score, int total, {String? categoryId, int daysAgo = 0}) {
  return QuizAttempt(
    id: 'a_${score}_${total}_$daysAgo',
    targetLanguageCode: 'es',
    categoryId: categoryId,
    score: score,
    total: total,
    takenAt: DateTime(2026, 11, 20).subtract(Duration(days: daysAgo)),
    answers: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ─── 1. Progress Calculations ──────────────────────────────────────────────

  group('ProgressCalculator', () {
    final categories = [
      const Category(
        id: 'greetings',
        title: 'Greetings',
        iconKey: 'greetings',
        names: {'en': 'Greetings', 'es': 'Saludos'},
      ),
      const Category(
        id: 'food',
        title: 'Food',
        iconKey: 'food',
        names: {'en': 'Food', 'es': 'Comida'},
      ),
    ];

    final phrases = [
      _phrase('p1', categoryId: 'greetings', en: 'Hello', es: 'Hola', fil: 'Kumusta'),
      _phrase('p2', categoryId: 'greetings', en: 'Bye', es: 'Adiós'), // no Filipino
      _phrase('p3', categoryId: 'food', en: 'Water', es: 'Agua', fil: 'Tubig'),
      _phrase('p4', categoryId: 'food', en: 'Inactive', es: 'Inactivo', isActive: false),
    ];

    test('computes learned per language ignoring inactive and missing translations', () {
      final learnedEs = {'p1', 'p3', 'p4'}; // p4 is inactive so excluded
      final learnedFil = {'p1'};

      final esProgress = ProgressCalculator.computeLanguageProgress(
        allPhrases: phrases,
        targetLanguageCode: 'es',
        isLearned: (id, lang) => lang == 'es' && learnedEs.contains(id),
      );
      expect(esProgress.totalCount, 3);
      expect(esProgress.learnedCount, 2);
      expect(esProgress.percentage, 67);

      final filProgress = ProgressCalculator.computeLanguageProgress(
        allPhrases: phrases,
        targetLanguageCode: 'fil',
        isLearned: (id, lang) => lang == 'fil' && learnedFil.contains(id),
      );
      expect(filProgress.totalCount, 2);
      expect(filProgress.learnedCount, 1);
      expect(filProgress.percentage, 50);
    });

    test('computes per-category counts accurately', () {
      final learnedEs = {'p1'};
      final items = ProgressCalculator.computeCategoryProgress(
        categories: categories,
        allPhrases: phrases,
        targetLanguageCode: 'es',
        isLearned: (id, lang) => learnedEs.contains(id),
      );

      expect(items.length, 2);
      expect(items[0].category.id, 'greetings');
      expect(items[0].learnedCount, 1);
      expect(items[0].totalCount, 2);
      expect(items[0].ratio, 0.5);

      expect(items[1].category.id, 'food');
      expect(items[1].learnedCount, 0);
      expect(items[1].totalCount, 1);
      expect(items[1].ratio, 0.0);
    });

    test('computes quiz stats for none, one, many, and enforces 20-attempt window & 10 display cap', () {
      // None
      final empty = ProgressCalculator.computeQuizStats(const []);
      expect(empty.quizzesTaken, 0);
      expect(empty.averagePercentage, 0.0);
      expect(empty.bestPercentage, 0.0);
      expect(empty.recentAttempts, isEmpty);

      // One
      final one = ProgressCalculator.computeQuizStats([_attempt(4, 5)]);
      expect(one.quizzesTaken, 1);
      expect(one.averagePercentRounded, 80);
      expect(one.bestPercentRounded, 80);
      expect(one.recentAttempts.length, 1);

      // Many (25 attempts: first 20 are 5/10 = 50%, last 5 are 10/10 = 100%)
      // Window of 20 should ignore the 21st..25th attempts!
      final many = [
        for (var i = 0; i < 20; i++) _attempt(5, 10, daysAgo: i),
        for (var i = 20; i < 25; i++) _attempt(10, 10, daysAgo: i),
      ];
      final stats = ProgressCalculator.computeQuizStats(many);
      expect(stats.quizzesTaken, 20);
      expect(stats.averagePercentRounded, 50);
      expect(stats.bestPercentRounded, 50);
      expect(stats.recentAttempts.length, 10);
      expect(stats.windowLimit, 20);
    });
  });

  // ─── 2. ProgressController Caching & Invalidation ──────────────────────────

  group('ProgressController', () {
    test('loads at most 20 attempts once per session and reloads after a new quiz is saved', () async {
      final authRepo = _FakeAuthRepo(
        initialUser: const AuthUser(uid: 'u1', email: 'a@b.com'),
      );
      final profileRepo = _FakeProfileRepo();
      final authCtrl = AuthController(
        authRepository: authRepo,
        profileRepository: profileRepo,
      );
      final attemptRepo = _FakeQuizAttemptRepo()..attempts = [_attempt(8, 10)];
      final quizCtrl = QuizController(repository: attemptRepo);
      final progressCtrl = ProgressController(
        repository: attemptRepo,
        authController: authCtrl,
        quizController: quizCtrl,
      );

      await progressCtrl.ensureLoaded('u1');
      expect(attemptRepo.getCalls, 1);
      expect(attemptRepo.lastRequestedLimit, 20);
      expect(progressCtrl.quizStats.quizzesTaken, 1);

      // Second ensureLoaded should NOT re-query Firestore
      await progressCtrl.ensureLoaded('u1');
      expect(attemptRepo.getCalls, 1);

      // Completing and saving a new quiz invalidates and reloads
      final pool = [
        _phrase('p1', categoryId: 'g', en: 'One', es: 'Uno'),
        _phrase('p2', categoryId: 'g', en: 'Two', es: 'Dos'),
        _phrase('p3', categoryId: 'g', en: 'Three', es: 'Tres'),
        _phrase('p4', categoryId: 'g', en: 'Four', es: 'Cuatro'),
      ];
      quizCtrl.startQuiz(
        allPhrases: pool,
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
        questionCount: 1,
      );
      quizCtrl.selectOption(quizCtrl.currentQuestion!.correctIndex);
      quizCtrl.submitAnswer();
      await quizCtrl.finishQuiz(uid: 'u1');
      await Future<void>.delayed(Duration.zero);

      expect(attemptRepo.getCalls, 2);
      expect(progressCtrl.quizStats.quizzesTaken, 2);

      progressCtrl.dispose();
      authCtrl.dispose();
      authRepo.dispose();
    });
  });

  // ─── 3. Settings Persistence & Shared Source of Truth ──────────────────────

  group('Settings Persistence & Theme Mode', () {
    test('persists themeMode, studyTextSizeIndex, and studyRecallMode under shared keys', () async {
      final ctrl1 = LanguageSettingsController();
      await ctrl1.load();
      expect(ctrl1.themeMode, ThemeMode.system);
      expect(ctrl1.studyTextSizeIndex, 0);
      expect(ctrl1.studyRecallMode, isFalse);

      await ctrl1.setThemeMode(ThemeMode.dark);
      await ctrl1.setStudyTextSizeIndex(2);
      await ctrl1.setStudyRecallMode(true);

      // Verify exact SharedPreferences keys shared with PhraseStudyScreen
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(LanguageSettingsController.keyThemeMode), 'dark');
      expect(prefs.getInt('study_text_size_index'), 2);
      expect(prefs.getBool('study_recall_mode'), isTrue);

      // Reload into a fresh controller
      final ctrl2 = LanguageSettingsController();
      await ctrl2.load();
      expect(ctrl2.themeMode, ThemeMode.dark);
      expect(ctrl2.studyTextSizeIndex, 2);
      expect(ctrl2.studyRecallMode, isTrue);
    });

    test('local appearance & reading settings do NOT sync to Firestore profile', () async {
      final settings = LanguageSettingsController();
      await settings.load();
      final authRepo = _FakeAuthRepo(
        initialUser: const AuthUser(uid: 'u1', email: 'a@b.com'),
      );
      final profileRepo = _FakeProfileRepo()
        ..profiles['u1'] = const UserProfile(
          uid: 'u1',
          displayName: 'Ana',
          nativeLanguageCode: 'en',
          targetLanguageCode: 'es',
        );
      final authCtrl = AuthController(
        authRepository: authRepo,
        profileRepository: profileRepo,
        languageSettingsController: settings,
      );
      await Future<void>.delayed(Duration.zero);

      await settings.setThemeMode(ThemeMode.light);
      await settings.setStudyTextSizeIndex(1);
      await settings.setStudyRecallMode(true);

      expect(profileRepo.updateLanguagesCallCount, 0);

      authCtrl.dispose();
      authRepo.dispose();
    });
  });

  // ─── 4. Display Name Validation & Payload ──────────────────────────────────

  group('Display Name Validation & Update', () {
    test('rejects empty and >100 char names, accepts valid names', () {
      expect(AuthController.validateDisplayName(''), isNotNull);
      expect(AuthController.validateDisplayName('   '), isNotNull);
      expect(AuthController.validateDisplayName('a' * 101), isNotNull);
      expect(AuthController.validateDisplayName('a' * 100), isNull);
      expect(AuthController.validateDisplayName('Maria Clara'), isNull);
    });

    test('updateDisplayName writes ONLY displayName field and updates state', () async {
      final authRepo = _FakeAuthRepo(
        initialUser: const AuthUser(uid: 'u1', email: 'a@b.com', displayName: 'Old'),
      );
      final profileRepo = _FakeProfileRepo()
        ..profiles['u1'] = const UserProfile(
          uid: 'u1',
          displayName: 'Old',
          nativeLanguageCode: 'en',
          targetLanguageCode: 'es',
        );
      final authCtrl = AuthController(
        authRepository: authRepo,
        profileRepository: profileRepo,
      );
      await Future<void>.delayed(Duration.zero);

      final res = await authCtrl.updateDisplayName('  New Name  ');
      expect(res.isSuccess, isTrue);
      expect(authCtrl.displayName, 'New Name');
      expect(profileRepo.displayNamePayloads.length, 1);
      expect(profileRepo.displayNamePayloads.first.keys.toList(), ['displayName']);
      expect(profileRepo.displayNamePayloads.first['displayName'], 'New Name');

      authCtrl.dispose();
      authRepo.dispose();
    });
  });

  // ─── 5. Email Verification & Cooldown ──────────────────────────────────────

  group('Email Verification & Resend Cooldown', () {
    test('enforces resend cooldown and refreshes status on reload', () async {
      var now = DateTime(2026, 11, 20, 12, 0, 0);
      final authRepo = _FakeAuthRepo(
        initialUser: const AuthUser(
          uid: 'u1',
          email: 'a@b.com',
          emailVerified: false,
        ),
      );
      final profileRepo = _FakeProfileRepo()
        ..profiles['u1'] = const UserProfile(
          uid: 'u1',
          nativeLanguageCode: 'en',
          targetLanguageCode: 'es',
        );
      final authCtrl = AuthController(
        authRepository: authRepo,
        profileRepository: profileRepo,
        clock: () => now,
      );

      expect(authCtrl.isEmailVerified, isFalse);
      expect(authCtrl.canSendVerificationEmail, isTrue);

      // First send succeeds
      final first = await authCtrl.sendEmailVerification();
      expect(first.isSuccess, isTrue);
      expect(authCtrl.canSendVerificationEmail, isFalse);
      expect(authCtrl.verificationCooldownRemaining.inSeconds, 60);

      // Immediate second send blocked by cooldown
      final second = await authCtrl.sendEmailVerification();
      expect(second.isError, isTrue);
      expect(authRepo.callLog.where((c) => c == 'sendEmailVerification').length, 1);

      // Advance clock past cooldown -> allowed again
      now = now.add(const Duration(seconds: 61));
      expect(authCtrl.canSendVerificationEmail, isTrue);
      final third = await authCtrl.sendEmailVerification();
      expect(third.isSuccess, isTrue);
      expect(authRepo.callLog.where((c) => c == 'sendEmailVerification').length, 2);

      // Reload user after verifying email
      authRepo.reloadedUserOverride = const AuthUser(
        uid: 'u1',
        email: 'a@b.com',
        emailVerified: true,
      );
      final reloadRes = await authCtrl.reloadEmailVerificationStatus();
      expect(reloadRes.isSuccess, isTrue);
      expect(reloadRes.dataOrNull, isTrue);
      expect(authCtrl.isEmailVerified, isTrue);

      authCtrl.dispose();
      authRepo.dispose();
    });
  });

  // ─── 6. Account Deletion Flow ──────────────────────────────────────────────

  group('Account Deletion Flow', () {
    test('re-auth failure deletes NOTHING', () async {
      final sharedLog = <String>[];
      final authRepo = _FakeAuthRepo(
        initialUser: const AuthUser(uid: 'u1', email: 'a@b.com'),
      )..reauthShouldFail = true;
      final profileRepo = _FakeProfileRepo(sharedCallLog: sharedLog)
        ..profiles['u1'] = const UserProfile(
          uid: 'u1',
          nativeLanguageCode: 'en',
          targetLanguageCode: 'es',
        );
      final authCtrl = AuthController(
        authRepository: authRepo,
        profileRepository: profileRepo,
      );
      await Future<void>.delayed(Duration.zero);

      final res = await authCtrl.deleteAccount(password: 'wrong-pass');
      expect(res.isError, isTrue);
      expect(authCtrl.isSignedIn, isTrue);
      expect(profileRepo.profiles.containsKey('u1'), isTrue);
      expect(sharedLog, isEmpty);
      expect(authRepo.callLog, ['reauth']);

      authCtrl.dispose();
      authRepo.dispose();
    });

    test('data deletion failure keeps auth user and allows retry', () async {
      final sharedLog = <String>[];
      final authRepo = _FakeAuthRepo(
        initialUser: const AuthUser(uid: 'u1', email: 'a@b.com'),
      );
      final profileRepo = _FakeProfileRepo(sharedCallLog: sharedLog)
        ..profiles['u1'] = const UserProfile(
          uid: 'u1',
          nativeLanguageCode: 'en',
          targetLanguageCode: 'es',
        )
        ..deleteDataShouldFail = true;
      final authCtrl = AuthController(
        authRepository: authRepo,
        profileRepository: profileRepo,
      );
      await Future<void>.delayed(Duration.zero);

      final failRes = await authCtrl.deleteAccount(password: 'correct-pass');
      expect(failRes.isError, isTrue);
      expect(authCtrl.isSignedIn, isTrue);
      expect(authRepo.callLog.contains('deleteAuthUser'), isFalse);

      // Retry succeeds when data deletion recovers
      profileRepo.deleteDataShouldFail = false;
      final retryRes = await authCtrl.deleteAccount(password: 'correct-pass');
      expect(retryRes.isSuccess, isTrue);
      expect(authCtrl.isGuest, isTrue);
      expect(authRepo.callLog.contains('deleteAuthUser'), isTrue);

      authCtrl.dispose();
      authRepo.dispose();
    });

    test('success deletes every subcollection, profile doc, then auth user, suppresses profile recreation, and clears controllers', () async {
      final orderLog = <String>[];
      final authRepo = _FakeAuthRepo(
        initialUser: const AuthUser(uid: 'u1', email: 'a@b.com'),
      );
      final profileRepo = _FakeProfileRepo(sharedCallLog: orderLog)
        ..profiles['u1'] = const UserProfile(
          uid: 'u1',
          nativeLanguageCode: 'en',
          targetLanguageCode: 'es',
        );
      final authCtrl = AuthController(
        authRepository: authRepo,
        profileRepository: profileRepo,
      );
      final phraseRepo = _FakeUserPhraseRepo()
        ..favorites = ['p1']
        ..learnedByLang = {'es': {'p1'}}
        ..recents = ['p1'];
      final userPhraseCtrl = UserPhraseController(
        repository: phraseRepo,
        authController: authCtrl,
      );
      final attemptRepo = _FakeQuizAttemptRepo()..attempts = [_attempt(8, 10)];
      final quizCtrl = QuizController(repository: attemptRepo);
      final progressCtrl = ProgressController(
        repository: attemptRepo,
        authController: authCtrl,
        quizController: quizCtrl,
      );
      await Future<void>.delayed(Duration.zero);
      await progressCtrl.ensureLoaded('u1');
      expect(userPhraseCtrl.favoritePhraseIds, ['p1']);
      expect(progressCtrl.attempts.length, 1);

      final createCountBefore = profileRepo.createProfileCallCount;

      final res = await authCtrl.deleteAccount(
        password: 'correct-pass',
        onDeleted: () {
          userPhraseCtrl.clear();
          quizCtrl.clear();
          progressCtrl.clear();
        },
      );
      await Future<void>.delayed(Duration.zero);

      expect(res.isSuccess, isTrue);
      expect(authCtrl.isGuest, isTrue);

      // Verify every listed subcollection was deleted, then profile doc
      expect(orderLog, [
        for (final sub in ProfileRepository.userSubcollections) 'deleteSubcollection:$sub',
        'deleteProfileDoc:u1',
      ]);
      expect(authRepo.callLog, ['reauth', 'deleteAuthUser']);

      // Profile must NOT be re-created during or after deletion
      expect(profileRepo.createProfileCallCount, createCountBefore);
      expect(profileRepo.profiles.containsKey('u1'), isFalse);

      // Per-user controllers cleared
      expect(userPhraseCtrl.favoritePhraseIds, isEmpty);
      expect(userPhraseCtrl.recentPhraseIds, isEmpty);
      expect(progressCtrl.attempts, isEmpty);
      expect(quizCtrl.hasActiveQuiz, isFalse);
      expect(quizCtrl.lastResult, isNull);

      progressCtrl.dispose();
      userPhraseCtrl.dispose();
      authCtrl.dispose();
      authRepo.dispose();
    });
  });

  // ─── 7. Widget Tests (Progress, Profile, Privacy) ──────────────────────────

  group('Stage 7 Widget Tests', () {
    setUp(() {
      BrowseDataService.setMockInstance(
        BrowseDataService(
          languageRepo: MockLanguageRepository(const [
            Language(code: 'en', name: 'English', nativeName: 'English'),
            Language(code: 'es', name: 'Spanish', nativeName: 'Español'),
            Language(code: 'fil', name: 'Filipino', nativeName: 'Filipino'),
          ]),
          categoryRepo: MockCategoryRepository(const [
            Category(
              id: 'greetings',
              title: 'Greetings',
              iconKey: 'greetings',
              names: {'en': 'Greetings', 'es': 'Saludos'},
            ),
          ]),
          phraseRepo: MockPhraseRepository([
            _phrase('p1', categoryId: 'greetings', en: 'Hello', es: 'Hola', fil: 'Kumusta'),
            _phrase('p2', categoryId: 'greetings', en: 'Good morning', es: 'Buenos días'),
          ]),
        ),
      );
    });

    testWidgets('ProgressScreen shows guest state with Sign In and Create Account', (tester) async {
      final settings = LanguageSettingsController();
      await settings.load();
      final authRepo = _FakeAuthRepo(initialUser: null);
      final authCtrl = AuthController(
        authRepository: authRepo,
        profileRepository: _FakeProfileRepo(),
      );
      authRepo.emitUser(null);

      await tester.pumpWidget(
        AppAuthScope(
          controller: authCtrl,
          child: AppSettingsScope(
            controller: settings,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const ProgressScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Track Your Progress'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);

      authCtrl.dispose();
      authRepo.dispose();
    });

    testWidgets('ProgressScreen shows empty state when signed in with nothing learned or quizzed', (tester) async {
      final settings = LanguageSettingsController();
      await settings.load();
      final authRepo = _FakeAuthRepo(
        initialUser: const AuthUser(uid: 'u1', email: 'a@b.com'),
      );
      final authCtrl = AuthController(
        authRepository: authRepo,
        profileRepository: _FakeProfileRepo(),
      );
      final userPhrases = UserPhraseController(
        repository: _FakeUserPhraseRepo(),
        authController: authCtrl,
      );
      final progressCtrl = ProgressController(
        repository: _FakeQuizAttemptRepo(),
        authController: authCtrl,
      );

      await tester.pumpWidget(
        AppAuthScope(
          controller: authCtrl,
          child: AppSettingsScope(
            controller: settings,
            child: AppUserPhraseScope(
              controller: userPhrases,
              child: AppProgressScope(
                controller: progressCtrl,
                child: MaterialApp(
                  theme: AppTheme.lightTheme,
                  home: const ProgressScreen(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Progress Yet'), findsOneWidget);
      expect(find.text('Browse Phrases'), findsOneWidget);
      expect(find.text('Take a Quiz'), findsOneWidget);

      progressCtrl.dispose();
      userPhrases.dispose();
      authCtrl.dispose();
      authRepo.dispose();
    });

    testWidgets('ProfileScreen shows email verification card when unverified and opens Privacy screen', (tester) async {
      final settings = LanguageSettingsController();
      await settings.load();
      final authRepo = _FakeAuthRepo(
        initialUser: const AuthUser(
          uid: 'u1',
          email: 'ana@example.com',
          displayName: 'Ana',
          emailVerified: false,
        ),
      );
      final profileRepo = _FakeProfileRepo()
        ..profiles['u1'] = const UserProfile(
          uid: 'u1',
          displayName: 'Ana',
          nativeLanguageCode: 'en',
          targetLanguageCode: 'es',
        );
      final authCtrl = AuthController(
        authRepository: authRepo,
        profileRepository: profileRepo,
      );

      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          GoRoute(path: '/privacy', builder: (_, _) => const PrivacyScreen()),
        ],
      );

      await tester.pumpWidget(
        AppAuthScope(
          controller: authCtrl,
          child: AppSettingsScope(
            controller: settings,
            child: ListenableBuilder(
              listenable: settings,
              builder: (_, _) => MaterialApp.router(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: settings.themeMode,
                routerConfig: router,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Unverified state visible
      expect(find.text('Email not verified'), findsOneWidget);
      expect(find.text('Verify your email'), findsOneWidget);
      expect(find.text('Send verification email'), findsOneWidget);
      expect(find.text("I've verified"), findsOneWidget);

      // Theme mode toggle updates settings & MaterialApp.themeMode
      await tester.scrollUntilVisible(find.text('Dark'), 200);
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(settings.themeMode, ThemeMode.dark);

      // Reading preference toggle updates shared settings
      await tester.scrollUntilVisible(find.text('Recall Mode'), 200);
      await tester.tap(find.text('Recall Mode'));
      await tester.pumpAndSettle();
      expect(settings.studyRecallMode, isTrue);

      // Open Privacy page
      await tester.scrollUntilVisible(find.text('Privacy'), 200);
      await tester.tap(find.text('Privacy'));
      await tester.pumpAndSettle();
      expect(find.text(PrivacyCopy.introTitle), findsOneWidget);

      authCtrl.dispose();
      authRepo.dispose();
    });
  });
}
