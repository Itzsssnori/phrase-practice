// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phrase_practice/models/auth_user.dart';
import 'package:phrase_practice/models/phrase.dart';
import 'package:phrase_practice/models/result.dart';
import 'package:phrase_practice/services/auth_controller.dart';
import 'package:phrase_practice/services/browse_data_service.dart';
import 'package:phrase_practice/services/language_settings_controller.dart';
import 'package:phrase_practice/services/user_phrase_controller.dart';
import 'package:phrase_practice/services/user_phrase_repository.dart';
import 'package:phrase_practice/screens/favorites_screen.dart';
import 'package:phrase_practice/screens/home_screen.dart';
import 'package:phrase_practice/widgets/app_auth_scope.dart';
import 'package:phrase_practice/widgets/app_settings_scope.dart';
import 'package:phrase_practice/widgets/app_user_phrase_scope.dart';
import 'package:phrase_practice/widgets/phrase_card.dart';

import 'stage_3_browse_test.dart';
import 'stage_4_auth_test.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class FakeUserPhraseRepository implements UserPhraseRepository {
  // uid -> ordered list of favorite slugs
  final Map<String, List<String>> _favorites = {};
  // uid -> langCode -> phraseSlug set
  final Map<String, Map<String, Set<String>>> _learned = {};
  // uid -> ordered list of recent phrase slugs
  final Map<String, List<String>> _recent = {};

  // Control knobs for failure injection
  bool failFavoriteWrites = false;
  bool failLoad = false;

  // Track write payloads to validate them
  final List<Map<String, dynamic>> favoriteWritePayloads = [];
  final List<Map<String, dynamic>> learnedWritePayloads = [];
  final List<Map<String, dynamic>> recentWritePayloads = [];

  @override
  Future<RepoResult<List<String>>> getFavoritePhraseIds(String uid) async {
    if (failLoad) return const RepoResult.error('simulated load error');
    return RepoResult.success(List<String>.from(_favorites[uid] ?? []));
  }

  @override
  Future<RepoResult<void>> addFavorite(String uid, String phraseSlug) async {
    if (failFavoriteWrites) return const RepoResult.error('simulated write error');
    favoriteWritePayloads.add({'uid': uid, 'slug': phraseSlug, 'op': 'add'});
    _favorites.putIfAbsent(uid, () => []).insert(0, phraseSlug);
    return const RepoResult.success(null);
  }

  @override
  Future<RepoResult<void>> removeFavorite(String uid, String phraseSlug) async {
    if (failFavoriteWrites) return const RepoResult.error('simulated write error');
    favoriteWritePayloads.add({'uid': uid, 'slug': phraseSlug, 'op': 'remove'});
    _favorites[uid]?.remove(phraseSlug);
    return const RepoResult.success(null);
  }

  @override
  Future<RepoResult<Map<String, Set<String>>>> getAllLearnedPhraseIds(String uid) async {
    if (failLoad) return const RepoResult.error('simulated load error');
    final raw = _learned[uid] ?? {};
    return RepoResult.success({
      for (final e in raw.entries) e.key: Set<String>.from(e.value),
    });
  }

  @override
  Future<RepoResult<void>> markPhraseLearned(
    String uid,
    String phraseSlug,
    String targetLanguageCode,
  ) async {
    learnedWritePayloads.add({
      'uid': uid,
      'slug': phraseSlug,
      'lang': targetLanguageCode,
      'op': 'mark',
    });
    _learned.putIfAbsent(uid, () => {}).putIfAbsent(targetLanguageCode, () => {}).add(phraseSlug);
    return const RepoResult.success(null);
  }

  @override
  Future<RepoResult<void>> unmarkPhraseLearned(
    String uid,
    String phraseSlug,
    String targetLanguageCode,
  ) async {
    learnedWritePayloads.add({
      'uid': uid,
      'slug': phraseSlug,
      'lang': targetLanguageCode,
      'op': 'unmark',
    });
    _learned[uid]?[targetLanguageCode]?.remove(phraseSlug);
    return const RepoResult.success(null);
  }

  @override
  Future<RepoResult<void>> recordRecentView(String uid, String phraseSlug) async {
    recentWritePayloads.add({'uid': uid, 'slug': phraseSlug});
    final list = _recent.putIfAbsent(uid, () => []);
    list.remove(phraseSlug);
    list.insert(0, phraseSlug);
    if (list.length > 20) list.removeRange(20, list.length);
    return const RepoResult.success(null);
  }

  @override
  Future<RepoResult<List<String>>> getRecentPhraseIds(String uid, {int limit = 20}) async {
    if (failLoad) return const RepoResult.error('simulated load error');
    final list = _recent[uid] ?? [];
    return RepoResult.success(list.take(limit).toList());
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Phrase _makePhrase(String id, {String categoryId = 'greetings'}) {
  return Phrase(
    id: id,
    categoryId: categoryId,
    isActive: true,
    sortOrder: 0,
  );
}

/// Creates a [UserPhraseController] backed by a [FakeUserPhraseRepository].
/// If [uid] is non-null, also calls [loadForUser] and waits.
Future<UserPhraseController> _makeController(
  FakeUserPhraseRepository repo, {
  String? uid,
}) async {
  final ctrl = UserPhraseController(repository: repo);
  if (uid != null) {
    await ctrl.loadForUser(uid);
  }
  return ctrl;
}

/// Creates an [AuthController] backed by [FakeAuthRepository].
/// Signs in [uid] if provided by emitting the user immediately.
Future<AuthController> _makeAuthController({String? uid}) async {
  final fakeAuth = FakeAuthRepository(
    initialUser: uid != null
        ? AuthUser(uid: uid, email: 'test@test.com', displayName: 'Test')
        : null,
  );
  final fakeProfile = FakeProfileRepository();
  final ctrl = AuthController(
    authRepository: fakeAuth,
    profileRepository: fakeProfile,
  );
  // Emit auth state so the controller settles
  if (uid != null) {
    fakeAuth.emitUser(AuthUser(uid: uid, email: 'test@test.com', displayName: 'Test'));
  } else {
    fakeAuth.emitUser(null);
  }
  await Future.microtask(() {});
  return ctrl;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    // Inject mock BrowseDataService so widget tests don't hit Firestore
    BrowseDataService.setMockInstance(BrowseDataService(
      languageRepo: MockLanguageRepository([]),
      categoryRepo: MockCategoryRepository([]),
      phraseRepo: MockPhraseRepository([]),
    ));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // =========================================================================
  // 1. UserPhraseController unit tests
  // =========================================================================
  group('UserPhraseController', () {
    test('isFavorite returns false before any load', () async {
      final repo = FakeUserPhraseRepository();
      final ctrl = await _makeController(repo);
      expect(ctrl.isFavorite('slug-a'), isFalse);
    });

    test('isFavorite returns true after toggleFavorite adds it', () async {
      final repo = FakeUserPhraseRepository();
      final ctrl = await _makeController(repo, uid: 'uid-1');

      await ctrl.toggleFavorite('slug-a');

      expect(ctrl.isFavorite('slug-a'), isTrue);
    });

    test('optimistic add: UI updates immediately (before repo write completes)', () async {
      final repo = FakeUserPhraseRepository();
      final ctrl = await _makeController(repo, uid: 'uid-1');

      // Don't await — check state immediately after kicking off the future
      final future = ctrl.toggleFavorite('slug-opt');
      // The optimistic update fires synchronously within the same microtask zone
      expect(ctrl.isFavorite('slug-opt'), isTrue,
          reason: 'Optimistic update must be applied synchronously');

      await future;
      // State remains true after write completes
      expect(ctrl.isFavorite('slug-opt'), isTrue);
    });

    test('toggling twice removes the favorite (add then remove)', () async {
      final repo = FakeUserPhraseRepository();
      final ctrl = await _makeController(repo, uid: 'uid-1');

      await ctrl.toggleFavorite('slug-b');
      expect(ctrl.isFavorite('slug-b'), isTrue);

      await ctrl.toggleFavorite('slug-b');
      expect(ctrl.isFavorite('slug-b'), isFalse);
    });

    test('rollback on write failure reverts optimistic add', () async {
      final repo = FakeUserPhraseRepository()..failFavoriteWrites = true;
      final ctrl = await _makeController(repo, uid: 'uid-1');

      final result = await ctrl.toggleFavorite('slug-fail');

      expect(ctrl.isFavorite('slug-fail'), isFalse,
          reason: 'State must be reverted after write failure');
      expect(result.isError, isTrue);
    });

    test('rollback on write failure reverts optimistic remove', () async {
      final repo = FakeUserPhraseRepository();
      final ctrl = await _makeController(repo, uid: 'uid-1');
      await ctrl.toggleFavorite('slug-c'); // add successfully
      repo.failFavoriteWrites = true;

      final result = await ctrl.toggleFavorite('slug-c'); // attempt remove — should fail

      expect(ctrl.isFavorite('slug-c'), isTrue,
          reason: 'Favorite must be restored after failed remove');
      expect(result.isError, isTrue);
    });

    test('double-tap guard: second toggle while in-flight is ignored', () async {
      final repo = FakeUserPhraseRepository();
      final ctrl = await _makeController(repo, uid: 'uid-1');

      // Fire two toggles without awaiting the first
      final f1 = ctrl.toggleFavorite('slug-d');
      final f2 = ctrl.toggleFavorite('slug-d'); // should be a no-op
      await Future.wait([f1, f2]);

      // After the two calls, the slug should be favourited (net +1 write)
      expect(ctrl.isFavorite('slug-d'), isTrue);
      // Only one repo write should have happened (the second was guarded)
      expect(repo.favoriteWritePayloads.where((p) => p['slug'] == 'slug-d').length, 1);
    });

    test('guest user: toggleFavorite returns error and nothing is written', () async {
      final repo = FakeUserPhraseRepository();
      final ctrl = await _makeController(repo); // no uid → guest

      final result = await ctrl.toggleFavorite('slug-guest');

      expect(result.isError, isTrue);
      expect(repo.favoriteWritePayloads, isEmpty);
    });

    test('clear() wipes all state immediately', () async {
      final repo = FakeUserPhraseRepository();
      final ctrl = await _makeController(repo, uid: 'uid-1');
      await ctrl.toggleFavorite('slug-e');
      await ctrl.toggleLearned('slug-e', 'es');
      expect(ctrl.isFavorite('slug-e'), isTrue);

      ctrl.clear();

      expect(ctrl.isFavorite('slug-e'), isFalse);
      expect(ctrl.isLearned('slug-e', 'es'), isFalse);
      expect(ctrl.favoritePhraseIds, isEmpty);
      expect(ctrl.recentPhraseIds, isEmpty);
    });

    test('loadForUser with new uid clears previous user state', () async {
      final repo = FakeUserPhraseRepository();
      final ctrl = await _makeController(repo, uid: 'uid-A');
      await ctrl.toggleFavorite('slug-uid-a');
      expect(ctrl.isFavorite('slug-uid-a'), isTrue);

      // Simulate different user signing in
      await ctrl.loadForUser('uid-B');

      expect(ctrl.isFavorite('slug-uid-a'), isFalse,
          reason: 'State from uid-A must not persist for uid-B');
    });

    test('isLearned per language: learning es does not mark fil', () async {
      final repo = FakeUserPhraseRepository();
      final ctrl = await _makeController(repo, uid: 'uid-1');

      await ctrl.toggleLearned('slug-f', 'es');

      expect(ctrl.isLearned('slug-f', 'es'), isTrue);
      expect(ctrl.isLearned('slug-f', 'fil'), isFalse);
    });

    test('toggleLearned unmarks when already learned', () async {
      final repo = FakeUserPhraseRepository();
      final ctrl = await _makeController(repo, uid: 'uid-1');

      await ctrl.toggleLearned('slug-g', 'es');
      expect(ctrl.isLearned('slug-g', 'es'), isTrue);

      await ctrl.toggleLearned('slug-g', 'es');
      expect(ctrl.isLearned('slug-g', 'es'), isFalse);
    });

    test('recordRecentView places slug at front and respects limit of 20', () async {
      final repo = FakeUserPhraseRepository();
      final ctrl = await _makeController(repo, uid: 'uid-1');

      // Add 21 unique slugs
      for (int i = 0; i < 21; i++) {
        ctrl.recordRecentView('slug-recent-$i');
      }
      // Allow the fire-and-forget background write to settle
      await Future.delayed(Duration.zero);

      expect(ctrl.recentPhraseIds.length, 20,
          reason: 'Recent list must be capped at 20');
      expect(ctrl.recentPhraseIds.first, 'slug-recent-20',
          reason: 'Most recently viewed phrase must be first');
    });

    test('recordRecentView moves existing slug to front instead of duplicating', () async {
      final repo = FakeUserPhraseRepository();
      final ctrl = await _makeController(repo, uid: 'uid-1');

      ctrl.recordRecentView('slug-h');
      ctrl.recordRecentView('slug-i');
      ctrl.recordRecentView('slug-h'); // revisit slug-h
      await Future.delayed(Duration.zero);

      expect(ctrl.recentPhraseIds.first, 'slug-h');
      expect(
        ctrl.recentPhraseIds.where((s) => s == 'slug-h').length,
        1,
        reason: 'slug-h must not be duplicated in the recent list',
      );
    });

    test('getLearnedCountForCategory counts only phrases in correct category and language', () async {
      final repo = FakeUserPhraseRepository();
      final ctrl = await _makeController(repo, uid: 'uid-1');

      final phrases = [
        _makePhrase('p1', categoryId: 'greetings'),
        _makePhrase('p2', categoryId: 'greetings'),
        _makePhrase('p3', categoryId: 'dining'),
      ];

      await ctrl.toggleLearned('p1', 'es');
      await ctrl.toggleLearned('p2', 'es');
      await ctrl.toggleLearned('p3', 'es');

      final count = ctrl.getLearnedCountForCategory('greetings', phrases, 'es');
      expect(count, 2, reason: 'Only phrases in greetings category should be counted');
    });
  });

  // =========================================================================
  // 2. Payload validation
  // =========================================================================
  group('Payload validation', () {
    test('addFavorite writes uid and slug (no extra fields)', () async {
      final repo = FakeUserPhraseRepository();
      final ctrl = await _makeController(repo, uid: 'uid-pay');

      await ctrl.toggleFavorite('slug-pay');

      expect(repo.favoriteWritePayloads.length, 1);
      final payload = repo.favoriteWritePayloads.first;
      expect(payload['uid'], 'uid-pay');
      expect(payload['slug'], 'slug-pay');
      expect(payload['op'], 'add');
    });

    test('markPhraseLearned writes phraseId and targetLanguageCode', () async {
      final repo = FakeUserPhraseRepository();
      final ctrl = await _makeController(repo, uid: 'uid-pay');

      await ctrl.toggleLearned('slug-learn', 'es');

      expect(repo.learnedWritePayloads.length, 1);
      final payload = repo.learnedWritePayloads.first;
      expect(payload['uid'], 'uid-pay');
      expect(payload['slug'], 'slug-learn');
      expect(payload['lang'], 'es');
      expect(payload['op'], 'mark');
    });

    test('recordRecentView writes uid and slug only', () async {
      final repo = FakeUserPhraseRepository();
      final ctrl = await _makeController(repo, uid: 'uid-pay');

      ctrl.recordRecentView('slug-recent');
      await Future.delayed(Duration.zero);

      expect(repo.recentWritePayloads.length, 1);
      final payload = repo.recentWritePayloads.first;
      expect(payload['uid'], 'uid-pay');
      expect(payload['slug'], 'slug-recent');
    });

    test('unmarkPhraseLearned fires when toggling off a learned phrase', () async {
      final repo = FakeUserPhraseRepository();
      final ctrl = await _makeController(repo, uid: 'uid-pay');

      await ctrl.toggleLearned('slug-unmark', 'fil');
      await ctrl.toggleLearned('slug-unmark', 'fil'); // toggle off

      final ops = repo.learnedWritePayloads.map((p) => p['op']).toList();
      expect(ops, containsAllInOrder(['mark', 'unmark']));
    });
  });

  // =========================================================================
  // 3. Widget tests – FavoritesScreen states
  // =========================================================================
  group('FavoritesScreen', () {
    Widget buildFavoritesApp({
      required UserPhraseController userPhraseCtrl,
      required AuthController authCtrl,
    }) {
      return AppAuthScope(
        controller: authCtrl,
        child: AppSettingsScope(
          controller: LanguageSettingsController(),
          child: AppUserPhraseScope(
            controller: userPhraseCtrl,
            child: const MaterialApp(
              home: FavoritesScreen(),
            ),
          ),
        ),
      );
    }

    testWidgets('guest state: shows Sign In button', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repo = FakeUserPhraseRepository();
      final authCtrl = await _makeAuthController(); // no uid → guest
      final ctrl = UserPhraseController(repository: repo);

      await tester.pumpWidget(buildFavoritesApp(
        userPhraseCtrl: ctrl,
        authCtrl: authCtrl,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sign In', findRichText: true), findsWidgets);
    });

    testWidgets('signed-in with no favorites: loading completes without crash', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repo = FakeUserPhraseRepository();
      final authCtrl = await _makeAuthController(uid: 'uid-load');
      final ctrl = UserPhraseController(repository: repo);
      await ctrl.loadForUser('uid-load');

      await tester.pumpWidget(buildFavoritesApp(
        userPhraseCtrl: ctrl,
        authCtrl: authCtrl,
      ));
      await tester.pumpAndSettle();

      // No loading spinner should remain after settle
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('error state: controller error message is non-null', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repo = FakeUserPhraseRepository()..failLoad = true;
      final authCtrl = await _makeAuthController(uid: 'uid-err');
      final ctrl = UserPhraseController(repository: repo);
      await ctrl.loadForUser('uid-err');

      await tester.pumpWidget(buildFavoritesApp(
        userPhraseCtrl: ctrl,
        authCtrl: authCtrl,
      ));
      await tester.pumpAndSettle();

      // The controller must surface a load error message
      expect(ctrl.errorMessage, isNotNull,
          reason: 'Controller must surface a load error message');
    });
  });

  // =========================================================================
  // 4. Orphan slug guard
  // =========================================================================
  group('Orphan phrase ID guard', () {
    test('orphan IDs in favorites load without crashing', () async {
      final repo = FakeUserPhraseRepository();
      repo._favorites['uid-orphan'] = ['orphan-slug-1', 'orphan-slug-2'];
      final ctrl = await _makeController(repo, uid: 'uid-orphan');

      await ctrl.loadForUser('uid-orphan');

      // Controller loads IDs fine; UI layer skips non-existent phrases
      expect(ctrl.favoritePhraseIds, containsAll(['orphan-slug-1', 'orphan-slug-2']));
    });

    test('orphan IDs in recent phrases load without crashing', () async {
      final repo = FakeUserPhraseRepository();
      repo._recent['uid-orphan'] = ['orphan-recent-1'];
      final ctrl = await _makeController(repo, uid: 'uid-orphan');

      await ctrl.loadForUser('uid-orphan');

      expect(ctrl.recentPhraseIds, contains('orphan-recent-1'));
    });
  });

  // =========================================================================
  // 5. Bug-fix regression tests
  // =========================================================================
  group('Bug fixes – favorite flow', () {
    test('toggleFavorite returns RepoResult.error on write failure (not silent)', () async {
      final repo = FakeUserPhraseRepository()..failFavoriteWrites = true;
      final ctrl = await _makeController(repo, uid: 'uid-bugfix');

      final result = await ctrl.toggleFavorite('slug-x');

      expect(result.isError, isTrue,
          reason: 'Write failure must be surfaced as RepoResult.error, not silently swallowed');
      expect(result.errorMessageOrNull, isNotNull);
    });

    test('toggleFavorite error message is non-empty string', () async {
      final repo = FakeUserPhraseRepository()..failFavoriteWrites = true;
      final ctrl = await _makeController(repo, uid: 'uid-bugfix');

      final result = await ctrl.toggleFavorite('slug-y');

      expect(result.errorMessageOrNull!.isNotEmpty, isTrue);
    });

    test('state reverts after failed add and in-flight guard is cleared', () async {
      final repo = FakeUserPhraseRepository()..failFavoriteWrites = true;
      final ctrl = await _makeController(repo, uid: 'uid-bugfix');

      await ctrl.toggleFavorite('slug-z');

      // State must be reverted
      expect(ctrl.isFavorite('slug-z'), isFalse);
      // In-flight guard must be cleared so a subsequent call works
      repo.failFavoriteWrites = false;
      await ctrl.toggleFavorite('slug-z');
      expect(ctrl.isFavorite('slug-z'), isTrue,
          reason: 'In-flight guard must be cleared after failure so retry succeeds');
    });

    test('controller notifies listeners after loadForUser completes', () async {
      final repo = FakeUserPhraseRepository();
      repo._favorites['uid-notify'] = ['fav-slug-1'];
      final ctrl = UserPhraseController(repository: repo);

      var notifyCount = 0;
      ctrl.addListener(() => notifyCount++);

      await ctrl.loadForUser('uid-notify');

      expect(notifyCount, greaterThanOrEqualTo(2),
          reason: 'Controller must call notifyListeners at load start and load end');
      expect(ctrl.isFavorite('fav-slug-1'), isTrue);
    });

    test('clear() triggers notifyListeners so UI can rebuild', () async {
      final repo = FakeUserPhraseRepository();
      final ctrl = await _makeController(repo, uid: 'uid-clear');
      await ctrl.toggleFavorite('slug-clear');

      var notified = false;
      ctrl.addListener(() => notified = true);

      ctrl.clear();

      expect(notified, isTrue, reason: 'clear() must call notifyListeners');
      expect(ctrl.favoritePhraseIds, isEmpty);
    });
  });

  // =========================================================================
  // 6. HomeScreen Favorites section tests
  // =========================================================================
  group('HomeScreen – Favorites section', () {
    Widget buildHomeApp({
      required UserPhraseController userPhraseCtrl,
      required AuthController authCtrl,
    }) {
      return AppAuthScope(
        controller: authCtrl,
        child: AppSettingsScope(
          controller: LanguageSettingsController(),
          child: AppUserPhraseScope(
            controller: userPhraseCtrl,
            child: const MaterialApp(
              home: HomeScreen(),
            ),
          ),
        ),
      );
    }

    testWidgets('Guest sees sign-in prompt card with Sign In button', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repo = FakeUserPhraseRepository();
      final authCtrl = await _makeAuthController(); // guest
      final userPhraseCtrl = UserPhraseController(repository: repo);

      await tester.pumpWidget(buildHomeApp(
        userPhraseCtrl: userPhraseCtrl,
        authCtrl: authCtrl,
      ));
      await tester.pumpAndSettle();

      expect(find.text('FAVORITES'), findsOneWidget);
      expect(find.text('Sign in to save phrases'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Signed in with no favorites sees quiet empty-state card', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repo = FakeUserPhraseRepository();
      final authCtrl = await _makeAuthController(uid: 'uid-empty-fav');
      final userPhraseCtrl = UserPhraseController(repository: repo);
      await userPhraseCtrl.loadForUser('uid-empty-fav');

      await tester.pumpWidget(buildHomeApp(
        userPhraseCtrl: userPhraseCtrl,
        authCtrl: authCtrl,
      ));
      await tester.pumpAndSettle();

      expect(find.text('FAVORITES'), findsOneWidget);
      expect(
        find.text('Tap the heart on any phrase to save it here'),
        findsOneWidget,
      );
      expect(find.text('See all'), findsNothing);
    });

    testWidgets('Signed in with favorites displays phrase cards and See all link', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final testPhrases = [
        _makePhrase('fav-1', categoryId: 'greetings'),
        _makePhrase('fav-2', categoryId: 'greetings'),
      ];
      BrowseDataService.setMockInstance(BrowseDataService(
        languageRepo: MockLanguageRepository([]),
        categoryRepo: MockCategoryRepository([]),
        phraseRepo: MockPhraseRepository(testPhrases),
      ));

      final repo = FakeUserPhraseRepository();
      repo._favorites['uid-with-fav'] = ['fav-1', 'fav-2'];
      final authCtrl = await _makeAuthController(uid: 'uid-with-fav');
      final userPhraseCtrl = UserPhraseController(repository: repo);
      await userPhraseCtrl.loadForUser('uid-with-fav');

      await tester.pumpWidget(buildHomeApp(
        userPhraseCtrl: userPhraseCtrl,
        authCtrl: authCtrl,
      ));
      await tester.pumpAndSettle();

      expect(find.text('FAVORITES'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);
      expect(find.byType(PhraseCard), findsNWidgets(2));
    });
  });
}
