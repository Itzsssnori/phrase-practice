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
  static const int maxDisplayNameLength = 100;
  static const Duration verificationResendCooldown = Duration(seconds: 60);

  final AuthRepository _authRepo;
  final ProfileRepository _profileRepo;
  final LanguageSettingsController? languageSettingsController;
  final DateTime Function() _now;

  StreamSubscription<AuthUser?>? _authSubscription;
  Completer<void>? _profileCompleter;
  bool _isSyncingFromProfile = false;
  bool _isDeletingAccount = false;
  bool _suppressProfileCreation = false;
  String? _lastSyncedNativeCode;
  String? _lastSyncedTargetCode;
  DateTime? _lastVerificationEmailSentAt;

  AuthStatus _status = AuthStatus.loading;
  AuthUser? _user;
  UserProfile? _profile;

  AuthController({
    AuthRepository? authRepository,
    ProfileRepository? profileRepository,
    this.languageSettingsController,
    DateTime Function()? clock,
  })  : _authRepo = authRepository ?? FirebaseAuthRepository(),
        _profileRepo = profileRepository ?? FirestoreProfileRepository(),
        _now = clock ?? DateTime.now {
    _init();
  }

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  UserProfile? get profile => _profile;

  bool get isLoading => _status == AuthStatus.loading;
  bool get isSignedIn => _status == AuthStatus.signedIn;
  bool get isGuest => _status == AuthStatus.signedOut;
  bool get isEmailVerified => _user?.emailVerified ?? false;
  bool get isDeletingAccount => _isDeletingAccount;

  String? get displayName => _profile?.displayName ?? _user?.displayName;
  String? get email => _user?.email;

  /// Remaining cooldown before another verification email can be sent.
  Duration get verificationCooldownRemaining {
    final lastSent = _lastVerificationEmailSentAt;
    if (lastSent == null) return Duration.zero;
    final elapsed = _now().difference(lastSent);
    if (elapsed >= verificationResendCooldown) return Duration.zero;
    return verificationResendCooldown - elapsed;
  }

  bool get canSendVerificationEmail =>
      isSignedIn && !isEmailVerified && verificationCooldownRemaining == Duration.zero;

  /// Validates a display name according to profile rules (non-empty, max 100 chars).
  static String? validateDisplayName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Please enter a display name.';
    }
    if (trimmed.length > maxDisplayNameLength) {
      return 'Display name must be $maxDisplayNameLength characters or fewer.';
    }
    return null;
  }

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
        _lastVerificationEmailSentAt = null;
        _status = AuthStatus.signedOut;
        notifyListeners();
      } else {
        if (_isDeletingAccount || _suppressProfileCreation) {
          return;
        }
        _user = authUser;
        _status = AuthStatus.signedIn;
        await _loadOrInitProfile(authUser);
        notifyListeners();
      }
    });
  }

  Future<void> _loadOrInitProfile(AuthUser authUser) async {
    if (_isDeletingAccount || _suppressProfileCreation) return;
    if (_profile != null && _profile!.uid == authUser.uid) return;
    if (_profileCompleter != null) {
      return _profileCompleter!.future;
    }
    final completer = Completer<void>();
    _profileCompleter = completer;

    try {
      final profileResult = await _profileRepo.getUserProfile(authUser.uid);

      if (_isDeletingAccount || _suppressProfileCreation) return;

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
        if (_isDeletingAccount || _suppressProfileCreation) return;

        // Profile document is missing; create it with current local settings
        final nativeCode = languageSettingsController?.nativeLanguageCode ?? 'en';
        final targetCode = languageSettingsController?.targetLanguageCode ?? 'es';

        final createResult = await _profileRepo.createProfile(
          uid: authUser.uid,
          displayName: authUser.displayName,
          nativeLanguageCode: nativeCode,
          targetLanguageCode: targetCode,
        );

        if (createResult.isSuccess && !_isDeletingAccount && !_suppressProfileCreation) {
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
    if (!isSignedIn || _user == null || _isSyncingFromProfile || _isDeletingAccount || _suppressProfileCreation) {
      return;
    }
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
    _suppressProfileCreation = false;
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
      _suppressProfileCreation = false;
      _user = result.dataOrNull;
      _status = AuthStatus.signedIn;
      await _loadOrInitProfile(_user!);
      notifyListeners();
    }

    return result;
  }

  /// Updates ONLY the user's `displayName` in their Firestore profile document.
  Future<RepoResult<void>> updateDisplayName(String displayName) async {
    final validationError = validateDisplayName(displayName);
    if (validationError != null) {
      return RepoResult.error(validationError);
    }

    final current = _user;
    if (!isSignedIn || current == null) {
      return const RepoResult.error('You must be signed in to update your display name.');
    }

    final trimmed = displayName.trim();
    final result = await _profileRepo.updateDisplayName(current.uid, trimmed);
    if (result.isSuccess) {
      if (_profile != null) {
        _profile = _profile!.copyWith(displayName: trimmed);
      } else {
        _user = current.copyWith(displayName: trimmed);
      }
      notifyListeners();
    }
    return result;
  }

  /// Sends an email verification link with a built-in resend cooldown.
  Future<RepoResult<void>> sendEmailVerification() async {
    if (!isSignedIn || _user == null) {
      return const RepoResult.error('You must be signed in to verify your email.');
    }
    if (isEmailVerified) {
      return const RepoResult.success(null);
    }

    final remaining = verificationCooldownRemaining;
    if (remaining > Duration.zero) {
      final seconds = remaining.inSeconds + (remaining.inMilliseconds % 1000 > 0 ? 1 : 0);
      return RepoResult.error(
        'Please wait ${seconds}s before sending another verification email.',
      );
    }

    final result = await _authRepo.sendEmailVerification();
    if (result.isSuccess) {
      _lastVerificationEmailSentAt = _now();
      notifyListeners();
    }
    return result;
  }

  /// Reloads the current Firebase Auth user to check if their email has been verified.
  Future<RepoResult<bool>> reloadEmailVerificationStatus() async {
    if (!isSignedIn || _user == null) {
      return const RepoResult.error('You are not signed in.');
    }

    final result = await _authRepo.reloadUser();
    if (result.isError) {
      return RepoResult.error(
        result.errorMessageOrNull ?? 'Could not check your email status. Please try again.',
      );
    }

    final reloaded = result.dataOrNull;
    if (reloaded != null) {
      _user = reloaded;
      notifyListeners();
      return RepoResult.success(reloaded.emailVerified);
    }
    return RepoResult.success(_user?.emailVerified ?? false);
  }

  /// Permanently deletes the current user's account in strict order:
  /// 1. Re-authenticate with [password] (if this fails, delete nothing).
  /// 2. Delete all user subcollections and `users/{uid}` document (if this fails, do NOT delete auth user).
  /// 3. Delete the Firebase Auth user.
  ///
  /// Profile auto-creation is suppressed throughout and after deletion.
  Future<RepoResult<void>> deleteAccount({
    required String password,
    VoidCallback? onDeleted,
  }) async {
    if (_isDeletingAccount) {
      return const RepoResult.error('Account deletion is already in progress.');
    }

    final current = _user;
    if (!isSignedIn || current == null) {
      return const RepoResult.error('You must be signed in to delete your account.');
    }

    _isDeletingAccount = true;
    _suppressProfileCreation = true;
    notifyListeners();

    // 1. Re-authenticate
    final reauthResult = await _authRepo.reauthenticateWithPassword(password);
    if (reauthResult.isError) {
      _isDeletingAccount = false;
      _suppressProfileCreation = false;
      notifyListeners();
      return reauthResult;
    }

    // 2. Delete all user subcollections and profile document
    final dataResult = await _profileRepo.deleteUserData(current.uid);
    if (dataResult.isError) {
      _isDeletingAccount = false;
      // Keep _suppressProfileCreation = true so profile is not recreated before retry.
      notifyListeners();
      return dataResult;
    }

    // 3. Delete Firebase Auth user
    final deleteAuthResult = await _authRepo.deleteAccount();
    if (deleteAuthResult.isError) {
      _isDeletingAccount = false;
      // Keep _suppressProfileCreation = true so profile is not recreated before retry.
      notifyListeners();
      return deleteAuthResult;
    }

    // 4. Clear auth state and notify callers to clear per-user controllers
    _user = null;
    _profile = null;
    _lastSyncedNativeCode = null;
    _lastSyncedTargetCode = null;
    _lastVerificationEmailSentAt = null;
    _status = AuthStatus.signedOut;
    _isDeletingAccount = false;

    onDeleted?.call();
    notifyListeners();
    return const RepoResult.success(null);
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
      _lastSyncedNativeCode = null;
      _lastSyncedTargetCode = null;
      _lastVerificationEmailSentAt = null;
      _suppressProfileCreation = false;
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
