import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/auth_user.dart';
import '../models/result.dart';
import '../models/user_profile.dart';
import 'auth_repository.dart';
import 'language_settings_controller.dart';
import 'profile_repository.dart';

/// Authentication state phases for the application.
enum AuthStatus {
  /// Checking initial authentication state (e.g. at app launch).
  loading,

  /// Unauthenticated guest user exploring the app without an account.
  signedOut,

  /// Authenticated user with an active Firebase session.
  signedIn,
}

/// Central state manager for user authentication, session state, and profile synchronization.
class AuthController extends ChangeNotifier {
  final AuthRepository _authRepo;
  final ProfileRepository _profileRepo;
  final LanguageSettingsController? languageSettingsController;

  StreamSubscription<AuthUser?>? _authSubscription;
  Completer<void>? _profileCompleter;
  bool _isSyncingFromProfile = false;
  String? _lastSyncedNativeCode;
  String? _lastSyncedTargetCode;

  AuthStatus _status = AuthStatus.loading;
  AuthUser? _user;
  UserProfile? _profile;

  AuthController({
    AuthRepository? authRepository,
    ProfileRepository? profileRepository,
    this.languageSettingsController,
  })  : _authRepo = authRepository ?? FirebaseAuthRepository(),
        _profileRepo = profileRepository ?? FirestoreProfileRepository() {
    _init();
  }

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  UserProfile? get profile => _profile;

  bool get isLoading => _status == AuthStatus.loading;
  bool get isSignedIn => _status == AuthStatus.signedIn;
  bool get isGuest => _status == AuthStatus.signedOut;

  String? get displayName => _profile?.displayName ?? _user?.displayName;
  String? get email => _user?.email;

  void _init() {
    // Listen for language setting changes to sync in background when signed in
    languageSettingsController?.addListener(_onLocalLanguagesChanged);

    // If an authenticated user session is already present, initialize it immediately
    final initialUser = _authRepo.currentUser;
    if (initialUser != null) {
      _user = initialUser;
      _status = AuthStatus.signedIn;
      _loadOrInitProfile(initialUser);
    }

    // Subscribe to auth state stream for subsequent changes
    _authSubscription = _authRepo.authStateChanges.listen((authUser) async {
      if (authUser == null) {
        _user = null;
        _profile = null;
        _lastSyncedNativeCode = null;
        _lastSyncedTargetCode = null;
        _status = AuthStatus.signedOut;
        notifyListeners();
      } else {
        _user = authUser;
        _status = AuthStatus.signedIn;
        await _loadOrInitProfile(authUser);
        notifyListeners();
      }
    });
  }

  Future<void> _loadOrInitProfile(AuthUser authUser) async {
    if (_profile != null && _profile!.uid == authUser.uid) return;
    if (_profileCompleter != null) {
      return _profileCompleter!.future;
    }
    final completer = Completer<void>();
    _profileCompleter = completer;

    try {
      final profileResult = await _profileRepo.getUserProfile(authUser.uid);

      if (profileResult.isSuccess && profileResult.dataOrNull != null) {
        _profile = profileResult.dataOrNull;
        // Apply profile languages to local settings controller on sign-in
        if (languageSettingsController != null && _profile != null) {
          _isSyncingFromProfile = true;
          _lastSyncedNativeCode = _profile!.nativeLanguageCode;
          _lastSyncedTargetCode = _profile!.targetLanguageCode;
          await languageSettingsController!.setLanguagePair(
            nativeCode: _profile!.nativeLanguageCode,
            targetCode: _profile!.targetLanguageCode,
          );
          _isSyncingFromProfile = false;
        }
      } else {
        // Profile document is missing; create it with current local settings
        final nativeCode = languageSettingsController?.nativeLanguageCode ?? 'en';
        final targetCode = languageSettingsController?.targetLanguageCode ?? 'es';

        final createResult = await _profileRepo.createProfile(
          uid: authUser.uid,
          displayName: authUser.displayName,
          nativeLanguageCode: nativeCode,
          targetLanguageCode: targetCode,
        );

        if (createResult.isSuccess) {
          _profile = createResult.dataOrNull;
          _lastSyncedNativeCode = nativeCode;
          _lastSyncedTargetCode = targetCode;
        }
      }
    } finally {
      completer.complete();
      _profileCompleter = null;
    }
  }

  void _onLocalLanguagesChanged() {
    if (!isSignedIn || _user == null || _isSyncingFromProfile) return;
    if (languageSettingsController == null) return;

    final newNative = languageSettingsController!.nativeLanguageCode;
    final newTarget = languageSettingsController!.targetLanguageCode;

    if (_lastSyncedNativeCode == newNative && _lastSyncedTargetCode == newTarget) {
      return;
    }

    _lastSyncedNativeCode = newNative;
    _lastSyncedTargetCode = newTarget;

    // Update in-memory profile
    if (_profile != null) {
      _profile = _profile!.copyWith(
        nativeLanguageCode: newNative,
        targetLanguageCode: newTarget,
      );
    }

    // Fire background Firestore update (non-blocking, failure must not break UI)
    _profileRepo
        .updateUserLanguages(
          _user!.uid,
          nativeLanguageCode: newNative,
          targetLanguageCode: newTarget,
        )
        .catchError((_) => const RepoResult<void>.error('Failed background sync'));
  }

  /// Registers a new user and immediately initializes their profile document in Firestore.
  Future<RepoResult<AuthUser>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final authResult = await _authRepo.registerWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );

    if (authResult.isError) {
      return authResult;
    }

    final newUser = authResult.dataOrNull!;
    _user = newUser;
    _status = AuthStatus.signedIn;
    await _loadOrInitProfile(newUser);
    notifyListeners();
    return authResult;
  }

  /// Signs in an existing user and loads their profile.
  Future<RepoResult<AuthUser>> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _authRepo.signInWithEmail(
      email: email,
      password: password,
    );

    if (result.isSuccess && result.dataOrNull != null) {
      _user = result.dataOrNull;
      _status = AuthStatus.signedIn;
      await _loadOrInitProfile(_user!);
      notifyListeners();
    }

    return result;
  }

  /// Sends a password reset email.
  Future<RepoResult<void>> sendPasswordReset(String email) async {
    return _authRepo.sendPasswordResetEmail(email);
  }

  /// Signs out the current user and returns to guest mode.
  Future<RepoResult<void>> signOut() async {
    final result = await _authRepo.signOut();
    if (result.isSuccess) {
      _user = null;
      _profile = null;
      _status = AuthStatus.signedOut;
      notifyListeners();
    }
    return result;
  }

  @override
  void dispose() {
    languageSettingsController?.removeListener(_onLocalLanguagesChanged);
    _authSubscription?.cancel();
    super.dispose();
  }
}
