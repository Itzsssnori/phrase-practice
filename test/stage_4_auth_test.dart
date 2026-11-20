import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phrase_practice/models/auth_user.dart';
import 'package:phrase_practice/models/category.dart';
import 'package:phrase_practice/models/language.dart';
import 'package:phrase_practice/models/phrase.dart';
import 'package:phrase_practice/models/phrase_translation.dart';
import 'package:phrase_practice/models/result.dart';
import 'package:phrase_practice/models/user_profile.dart';
import 'package:phrase_practice/router/app_router.dart';
import 'package:phrase_practice/screens/forgot_password_screen.dart';
import 'package:phrase_practice/screens/login_screen.dart';
import 'package:phrase_practice/screens/profile_screen.dart';
import 'package:phrase_practice/services/auth_controller.dart';
import 'package:phrase_practice/services/auth_repository.dart';
import 'package:phrase_practice/services/auth_validators.dart';
import 'package:phrase_practice/services/browse_data_service.dart';
import 'package:phrase_practice/services/language_settings_controller.dart';
import 'package:phrase_practice/services/profile_repository.dart';
import 'package:phrase_practice/widgets/app_auth_scope.dart';
import 'package:phrase_practice/widgets/app_settings_scope.dart';
import 'package:phrase_practice/widgets/require_sign_in.dart';

import 'stage_3_browse_test.dart';

/// Fake implementation of [AuthRepository] for unit testing.
class FakeAuthRepository implements AuthRepository {
  final StreamController<AuthUser?> _authController = StreamController<AuthUser?>.broadcast();
  AuthUser? _current;

  FakeAuthRepository({AuthUser? initialUser}) : _current = initialUser;

  void emitUser(AuthUser? user) {
    _current = user;
    _authController.add(user);
  }

  @override
  Stream<AuthUser?> get authStateChanges => _authController.stream;

  @override
  AuthUser? get currentUser => _current;

  static final Map<String, String> _globalUids = {};

  String _getUidForEmail(String email) {
    if (email == 'maria@example.com') return 'test-uid-123';
    return _globalUids.putIfAbsent(email, () => 'uid-${email.hashCode.abs()}');
  }

  @override
  Future<RepoResult<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (email == 'error@test.com' || password == 'wrong-pass') {
      return RepoResult.error(AuthErrorMapper.mapCode('wrong-password'));
    }
    if (email == 'unknown@test.com') {
      return RepoResult.error(AuthErrorMapper.mapCode('user-not-found'));
    }
    final uid = _getUidForEmail(email);
    final user = AuthUser(uid: uid, email: email, displayName: 'Test User');
    emitUser(user);
    return RepoResult.success(user);
  }

  @override
  Future<RepoResult<AuthUser>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (email == 'existing@test.com') {
      return RepoResult.error(AuthErrorMapper.mapCode('email-already-in-use'));
    }
    final uid = _getUidForEmail(email);
    final user = AuthUser(uid: uid, email: email, displayName: displayName);
    emitUser(user);
    return RepoResult.success(user);
  }

  @override
  Future<RepoResult<void>> sendPasswordResetEmail(String email) async {
    return const RepoResult.success(null);
  }

  @override
  Future<RepoResult<void>> signOut() async {
    emitUser(null);
    return const RepoResult.success(null);
  }

  @override
  Future<RepoResult<void>> sendEmailVerification() async => const RepoResult.success(null);

  @override
  Future<RepoResult<AuthUser?>> reloadUser() async => RepoResult.success(_current);

  @override
  Future<RepoResult<void>> reauthenticateWithPassword(String password) async =>
      const RepoResult.success(null);

  @override
  Future<RepoResult<void>> deleteAccount() async {
    emitUser(null);
    return const RepoResult.success(null);
  }

  void dispose() {
    _authController.close();
  }
}

/// Fake implementation of [ProfileRepository] for testing Firestore interactions.
class FakeProfileRepository implements ProfileRepository {
  final Map<String, UserProfile> profiles = {};
  final List<Map<String, dynamic>> createdPayloads = [];
  int updateLanguagesCallCount = 0;
  String? lastUpdatedNative;
  String? lastUpdatedTarget;

  @override
  Future<RepoResult<UserProfile>> getUserProfile(String uid) async {
    final profile = profiles[uid];
    if (profile == null) {
      return RepoResult.empty('Profile not found');
    }
    return RepoResult.success(profile);
  }

  @override
  Future<RepoResult<UserProfile>> createProfile({
    required String uid,
    String? displayName,
    required String nativeLanguageCode,
    required String targetLanguageCode,
  }) async {
    final payload = <String, dynamic>{
      if (displayName != null && displayName.isNotEmpty) 'displayName': displayName,
      'nativeLanguageCode': nativeLanguageCode,
      'targetLanguageCode': targetLanguageCode,
      'preferences': <String, dynamic>{},
      'createdAt': 'SERVER_TIMESTAMP',
    };
    createdPayloads.add(payload);

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
  Future<RepoResult<void>> updateUserLanguages(
    String uid, {
    required String nativeLanguageCode,
    required String targetLanguageCode,
  }) async {
    updateLanguagesCallCount++;
    lastUpdatedNative = nativeLanguageCode;
    lastUpdatedTarget = targetLanguageCode;
    final existing = profiles[uid];
    if (existing != null) {
      profiles[uid] = existing.copyWith(
        nativeLanguageCode: nativeLanguageCode,
        targetLanguageCode: targetLanguageCode,
      );
    }
    return const RepoResult.success(null);
  }

  @override
  Future<RepoResult<void>> updateDisplayName(String uid, String displayName) async {
    final existing = profiles[uid];
    if (existing != null) {
      profiles[uid] = existing.copyWith(displayName: displayName);
    }
    return const RepoResult.success(null);
  }

  @override
  Future<RepoResult<void>> deleteUserData(String uid) async {
    profiles.remove(uid);
    return const RepoResult.success(null);
  }

  @override
  Future<RepoResult<void>> updateUserPreferences(String uid, Map<String, dynamic> preferences) async {
    return const RepoResult.success(null);
  }

  @override
  Future<RepoResult<void>> createOrUpdateProfile(UserProfile profile) async {
    profiles[profile.uid] = profile;
    return const RepoResult.success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockLanguages = [
    const Language(code: 'en', name: 'English', nativeName: 'English'),
    const Language(code: 'es', name: 'Spanish', nativeName: 'Español'),
  ];
  final mockCategories = [
    const Category(
      id: 'greetings',
      sortOrder: 1,
      iconKey: 'greetings',
      names: {'en': 'Greetings', 'es': 'Saludos'},
      phraseCount: 1,
    ),
  ];
  final mockPhrases = [
    const Phrase(
      id: 'p1',
      categoryId: 'greetings',
      sortOrder: 1,
      translations: {
        'en': PhraseTranslation(text: 'Hello'),
        'es': PhraseTranslation(text: 'Hola'),
      },
    ),
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BrowseDataService.setMockInstance(
      BrowseDataService(
        languageRepo: MockLanguageRepository(mockLanguages),
        categoryRepo: MockCategoryRepository(mockCategories),
        phraseRepo: MockPhraseRepository(mockPhrases),
      ),
    );
  });

  group('AuthValidators', () {
    test('validateDisplayName checks presence and length constraints', () {
      expect(AuthValidators.validateDisplayName(null), 'Please enter your name.');
      expect(AuthValidators.validateDisplayName(''), 'Please enter your name.');
      expect(AuthValidators.validateDisplayName('   '), 'Please enter your name.');
      expect(AuthValidators.validateDisplayName('A' * 101), 'Name must be 100 characters or fewer.');
      expect(AuthValidators.validateDisplayName('Alex Smith'), isNull);
    });

    test('validateEmail validates regex syntax accurately', () {
      expect(AuthValidators.validateEmail(null), 'Please enter your email.');
      expect(AuthValidators.validateEmail(''), 'Please enter your email.');
      expect(AuthValidators.validateEmail('plainaddress'), 'Please enter a valid email address.');
      expect(AuthValidators.validateEmail('@missingusername.com'), 'Please enter a valid email address.');
      expect(AuthValidators.validateEmail('user@domain'), 'Please enter a valid email address.');
      expect(AuthValidators.validateEmail('valid.user+test@domain.co'), isNull);
    });

    test('validatePassword enforces 8 character minimum', () {
      expect(AuthValidators.validatePassword(null), 'Please enter a password.');
      expect(AuthValidators.validatePassword(''), 'Please enter a password.');
      expect(AuthValidators.validatePassword('short'), 'Password must be at least 8 characters.');
      expect(AuthValidators.validatePassword('1234567'), 'Password must be at least 8 characters.');
      expect(AuthValidators.validatePassword('12345678'), isNull);
      expect(AuthValidators.validatePassword('superStrongSecretPass123!'), isNull);
    });

    test('validateConfirmPassword enforces match against original password', () {
      expect(AuthValidators.validateConfirmPassword(null, 'password123'), 'Please confirm your password.');
      expect(AuthValidators.validateConfirmPassword('', 'password123'), 'Please confirm your password.');
      expect(AuthValidators.validateConfirmPassword('wrong', 'password123'), 'Passwords do not match.');
      expect(AuthValidators.validateConfirmPassword('password123', 'password123'), isNull);
    });
  });

  group('AuthErrorMapper', () {
    test('maps wrong credentials and user-not-found to identical generic message', () {
      final msg1 = AuthErrorMapper.mapCode('wrong-password');
      final msg2 = AuthErrorMapper.mapCode('user-not-found');
      final msg3 = AuthErrorMapper.mapCode('invalid-credential');

      expect(msg1, AuthErrorMapper.genericWrongCredentials);
      expect(msg2, AuthErrorMapper.genericWrongCredentials);
      expect(msg3, AuthErrorMapper.genericWrongCredentials);
      expect(msg1, 'Incorrect email or password.');
    });

    test('maps all standard Firebase Auth error codes to user-friendly messages', () {
      expect(AuthErrorMapper.mapCode('invalid-email'), 'Please enter a valid email address.');
      expect(AuthErrorMapper.mapCode('email-already-in-use'), 'An account already exists with this email address.');
      expect(AuthErrorMapper.mapCode('weak-password'), 'Password is too weak. Please use at least 8 characters.');
      expect(AuthErrorMapper.mapCode('too-many-requests'), 'Too many failed attempts. Please try again later.');
      expect(AuthErrorMapper.mapCode('network-request-failed'), 'Network error. Please check your connection and try again.');
      expect(AuthErrorMapper.mapCode('user-disabled'), 'This account has been disabled. Please contact support.');
      expect(AuthErrorMapper.mapCode('unknown-error-xyz'), 'An error occurred during authentication. Please try again.');
    });

    test('resetNeutralMessage preserves privacy and security', () {
      expect(
        AuthErrorMapper.resetNeutralMessage,
        'If an account exists for that email, we sent a reset link.',
      );
    });
  });

  group('AuthController & Profile Synchronization', () {
    late FakeAuthRepository fakeAuth;
    late FakeProfileRepository fakeProfile;
    late LanguageSettingsController settingsController;

    setUp(() async {
      fakeAuth = FakeAuthRepository();
      fakeProfile = FakeProfileRepository();
      final prefs = await SharedPreferences.getInstance();
      settingsController = LanguageSettingsController(preferences: prefs);
      await settingsController.load();
    });

    tearDown(() {
      fakeAuth.dispose();
      settingsController.dispose();
    });

    test('initializes in loading status then resolves to signedOut for guests', () async {
      final controller = AuthController(
        authRepository: fakeAuth,
        profileRepository: fakeProfile,
        languageSettingsController: settingsController,
      );

      expect(controller.status, AuthStatus.loading);
      expect(controller.isLoading, isTrue);

      // Emit null (guest)
      fakeAuth.emitUser(null);
      await Future<void>.delayed(Duration.zero);

      expect(controller.status, AuthStatus.signedOut);
      expect(controller.isGuest, isTrue);
      expect(controller.isSignedIn, isFalse);
      expect(controller.user, isNull);
    });

    test('sign in applies user profile languages to local settings', () async {
      final controller = AuthController(
        authRepository: fakeAuth,
        profileRepository: fakeProfile,
        languageSettingsController: settingsController,
      );

      // Seed a profile in Firestore
      fakeProfile.profiles['test-uid-123'] = const UserProfile(
        uid: 'test-uid-123',
        displayName: 'Maria Santos',
        nativeLanguageCode: 'fil',
        targetLanguageCode: 'es',
        preferences: {},
      );

      final result = await controller.signIn(
        email: 'maria@example.com',
        password: 'password123',
      );

      expect(result.isSuccess, isTrue);
      expect(controller.isSignedIn, isTrue);
      expect(controller.displayName, 'Maria Santos');
      expect(settingsController.nativeLanguageCode, 'fil');
      expect(settingsController.targetLanguageCode, 'es');
    });

    test('registration writes profile adhering strictly to firestore.rules payload', () async {
      final controller = AuthController(
        authRepository: fakeAuth,
        profileRepository: fakeProfile,
        languageSettingsController: settingsController,
      );

      await settingsController.setLanguagePair(nativeCode: 'en', targetCode: 'fil');

      final result = await controller.register(
        email: 'newuser@example.com',
        password: 'password123',
        displayName: 'New Learner',
      );

      expect(result.isSuccess, isTrue);
      expect(controller.isSignedIn, isTrue);
      expect(fakeProfile.createdPayloads.length, 1);

      final payload = fakeProfile.createdPayloads.first;
      // Must ONLY contain allowed fields: displayName, nativeLanguageCode, targetLanguageCode, preferences, createdAt
      const allowedFields = {'displayName', 'nativeLanguageCode', 'targetLanguageCode', 'preferences', 'createdAt'};
      expect(payload.keys.toSet().difference(allowedFields), isEmpty);
      // uid and email must NOT be inside the document payload
      expect(payload.containsKey('email'), isFalse);
      expect(payload.containsKey('uid'), isFalse);
      expect(payload['displayName'], 'New Learner');
      expect(payload['nativeLanguageCode'], 'en');
      expect(payload['targetLanguageCode'], 'fil');
      expect(payload['preferences'], isEmpty);
    });

    test('changing language while signed in updates Firestore profile in background', () async {
      final controller = AuthController(
        authRepository: fakeAuth,
        profileRepository: fakeProfile,
        languageSettingsController: settingsController,
      );

      fakeProfile.profiles['test-uid-123'] = const UserProfile(
        uid: 'test-uid-123',
        nativeLanguageCode: 'en',
        targetLanguageCode: 'es',
      );

      await controller.signIn(
        email: 'test@example.com',
        password: 'password123',
      );

      final initialCount = fakeProfile.updateLanguagesCallCount;

      // User changes target language to Filipino
      await settingsController.setTargetLanguage('fil');
      await Future<void>.delayed(Duration.zero);

      expect(fakeProfile.updateLanguagesCallCount, initialCount + 1);
      expect(fakeProfile.lastUpdatedNative, 'en');
      expect(fakeProfile.lastUpdatedTarget, 'fil');
    });

    test('changing language while guest does NOT trigger Firestore profile update', () async {
      // ignore: unused_local_variable
      final controller = AuthController(
        authRepository: fakeAuth,
        profileRepository: fakeProfile,
        languageSettingsController: settingsController,
      );
      fakeAuth.emitUser(null);
      await Future<void>.delayed(Duration.zero);

      final initialCount = fakeProfile.updateLanguagesCallCount;

      await settingsController.setTargetLanguage('fil');
      await Future<void>.delayed(Duration.zero);

      expect(fakeProfile.updateLanguagesCallCount, initialCount);
    });

    test('signOut resets user session to signedOut', () async {
      final controller = AuthController(
        authRepository: fakeAuth,
        profileRepository: fakeProfile,
        languageSettingsController: settingsController,
      );

      await controller.signIn(
        email: 'test@example.com',
        password: 'password123',
      );
      expect(controller.isSignedIn, isTrue);

      await controller.signOut();
      expect(controller.status, AuthStatus.signedOut);
      expect(controller.isGuest, isTrue);
      expect(controller.user, isNull);
    });
  });

  group('Route Guards', () {
    late FakeAuthRepository fakeAuth;
    late FakeProfileRepository fakeProfile;
    late LanguageSettingsController settingsController;

    setUp(() async {
      fakeAuth = FakeAuthRepository();
      fakeProfile = FakeProfileRepository();
      final prefs = await SharedPreferences.getInstance();
      settingsController = LanguageSettingsController(preferences: prefs);
      await settingsController.load();
    });

    testWidgets('Guest is redirected from splash to onboarding if not onboarded', (tester) async {
      final authController = AuthController(
        authRepository: fakeAuth,
        profileRepository: fakeProfile,
        languageSettingsController: settingsController,
      );
      fakeAuth.emitUser(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      final router = createAppRouter(
        authController: authController,
        settingsController: settingsController,
      );

      await tester.pumpWidget(
        AppAuthScope(
          controller: authController,
          child: AppSettingsScope(
            controller: settingsController,
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/onboarding');
    });

    testWidgets('Signed-in user on /login is redirected to /home', (tester) async {
      final signedInAuth = FakeAuthRepository(
        initialUser: const AuthUser(uid: 'user-1', email: 'user@test.com'),
      );
      final authController = AuthController(
        authRepository: signedInAuth,
        profileRepository: fakeProfile,
        languageSettingsController: settingsController,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      final router = createAppRouter(
        authController: authController,
        settingsController: settingsController,
      );

      await tester.pumpWidget(
        AppAuthScope(
          controller: authController,
          child: AppSettingsScope(
            controller: settingsController,
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Attempt to navigate to /login
      router.go('/login');
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/home');
    });
  });

  group('requireSignIn helper', () {
    late FakeProfileRepository fakeProfile;

    setUp(() {
      fakeProfile = FakeProfileRepository();
    });

    testWidgets('returns true immediately when user is signed in', (tester) async {
      final fakeAuth = FakeAuthRepository(
        initialUser: const AuthUser(uid: 'user-1', email: 'user@test.com'),
      );
      final authController = AuthController(
        authRepository: fakeAuth,
        profileRepository: fakeProfile,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(authController.isSignedIn, isTrue);

      bool? result;
      await tester.pumpWidget(
        AppAuthScope(
          controller: authController,
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await requireSignIn(context);
                },
                child: const Text('Check Auth'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Check Auth'));
      await tester.pump();

      expect(result, isTrue);
      // No bottom sheet shown
      expect(find.text('Sign in to use this feature'), findsNothing);
    });

    testWidgets('shows modal sheet and returns false when user is guest', (tester) async {
      final fakeAuth = FakeAuthRepository();
      final authController = AuthController(
        authRepository: fakeAuth,
        profileRepository: fakeProfile,
      );
      fakeAuth.emitUser(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      bool? result;
      await tester.pumpWidget(
        AppAuthScope(
          controller: authController,
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await requireSignIn(context);
                },
                child: const Text('Check Auth'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Check Auth'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to use this feature'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);

      // Close modal sheet by tapping outside or dismiss
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });

  group('Stage 4 User Checklist Scenarios', () {
    late FakeAuthRepository fakeAuth;
    late FakeProfileRepository fakeProfile;
    late LanguageSettingsController settingsController;

    setUp(() async {
      fakeAuth = FakeAuthRepository();
      fakeProfile = FakeProfileRepository();
      final prefs = await SharedPreferences.getInstance();
      settingsController = LanguageSettingsController(preferences: prefs);
      await settingsController.load();
    });

    testWidgets('LoginScreen shows identical generic error for wrong password vs unknown account', (tester) async {
      final authController = AuthController(
        authRepository: fakeAuth,
        profileRepository: fakeProfile,
        languageSettingsController: settingsController,
      );
      fakeAuth.emitUser(null);
      await tester.pump();

      await tester.pumpWidget(
        AppAuthScope(
          controller: authController,
          child: AppSettingsScope(
            controller: settingsController,
            child: const MaterialApp(home: LoginScreen()),
          ),
        ),
      );

      // 1. Wrong password
      await tester.enterText(find.byType(TextFormField).first, 'registered@test.com');
      await tester.enterText(find.byType(TextFormField).last, 'wrong-pass');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect email or password.'), findsOneWidget);

      // 2. Unknown account
      await tester.enterText(find.byType(TextFormField).first, 'unknown@test.com');
      await tester.enterText(find.byType(TextFormField).last, 'some-pass-123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect email or password.'), findsOneWidget);
    });

    testWidgets('ForgotPasswordScreen shows identical neutral confirmation for registered and unknown emails', (tester) async {
      final authController = AuthController(
        authRepository: fakeAuth,
        profileRepository: fakeProfile,
        languageSettingsController: settingsController,
      );
      fakeAuth.emitUser(null);
      await tester.pump();

      await tester.pumpWidget(
        AppAuthScope(
          controller: authController,
          child: AppSettingsScope(
            controller: settingsController,
            child: const MaterialApp(home: ForgotPasswordScreen()),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'anyuser@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      expect(find.text('If an account exists for that email, we sent a reset link.'), findsOneWidget);
    });

    test('Session restoration: app initialization with existing session stays signed in', () async {
      final existingAuth = FakeAuthRepository(
        initialUser: const AuthUser(uid: 'persisted-uid', email: 'persisted@test.com'),
      );
      final controller = AuthController(
        authRepository: existingAuth,
        profileRepository: fakeProfile,
        languageSettingsController: settingsController,
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.isSignedIn, isTrue);
      expect(controller.isGuest, isFalse);
      expect(controller.status, AuthStatus.signedIn);
    });

    testWidgets('Guest browsing: profile displays guest mode without forcing sign in', (tester) async {
      final authController = AuthController(
        authRepository: fakeAuth,
        profileRepository: fakeProfile,
        languageSettingsController: settingsController,
      );
      fakeAuth.emitUser(null);
      await tester.pump();

      await tester.pumpWidget(
        AppAuthScope(
          controller: authController,
          child: AppSettingsScope(
            controller: settingsController,
            child: const MaterialApp(home: ProfileScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Guest Explorer'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      // No blocking dialog
      expect(find.text('Sign in to use this feature'), findsNothing);
    });

    test('Multi-session language sync: changing language updates profile and syncs to new session', () async {
      // Session A: User logs in, changes language to Filipino
      final authA = FakeAuthRepository();
      final prefsA = await SharedPreferences.getInstance();
      final settingsA = LanguageSettingsController(preferences: prefsA);
      await settingsA.load();

      final controllerA = AuthController(
        authRepository: authA,
        profileRepository: fakeProfile,
        languageSettingsController: settingsA,
      );

      await controllerA.register(
        email: 'multisession@test.com',
        password: 'password123',
        displayName: 'Traveler',
      );

      // Change target language to Filipino in Session A
      await settingsA.setTargetLanguage('fil');
      await Future<void>.delayed(Duration.zero);

      // Verify Firestore profile document was updated
      expect(fakeProfile.lastUpdatedTarget, 'fil');

      // Session B: Fresh device/browser session with default English/Spanish
      SharedPreferences.setMockInitialValues({});
      final prefsB = await SharedPreferences.getInstance();
      final settingsB = LanguageSettingsController(preferences: prefsB);
      await settingsB.load();
      expect(settingsB.targetLanguageCode, 'es'); // Initially default Spanish

      final authB = FakeAuthRepository();
      final controllerB = AuthController(
        authRepository: authB,
        profileRepository: fakeProfile,
        languageSettingsController: settingsB,
      );

      // User signs in on Session B
      await controllerB.signIn(
        email: 'multisession@test.com',
        password: 'password123',
      );

      // Settings on Session B immediately sync to Filipino from profile
      expect(settingsB.targetLanguageCode, 'fil');
    });
  });
}
