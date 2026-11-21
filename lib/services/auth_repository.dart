import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/auth_user.dart';
import '../models/result.dart';

/// Error mapper translating Firebase Auth codes to friendly, secure user messages.
class AuthErrorMapper {
  AuthErrorMapper._();

  static const String genericWrongCredentials = 'Incorrect email or password.';
  static const String resetNeutralMessage =
      'If an account exists for that email, we sent a reset link.';

  static String mapCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        // Use ONE generic message for wrong password and unknown account; do not reveal which.
        return genericWrongCredentials;
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 8 characters.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'requires-recent-login':
        return 'Please re-enter your password to confirm this action.';
      default:
        return 'An error occurred during authentication. Please try again.';
    }
  }
}

/// Abstract interface for user authentication.
abstract interface class AuthRepository {
  /// Stream of authentication state changes.
  Stream<AuthUser?> get authStateChanges;

  /// Currently signed in user, or null if guest.
  AuthUser? get currentUser;

  /// Registers a new user with email, password, and display name.
  Future<RepoResult<AuthUser>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  /// Signs in an existing user with email and password.
  Future<RepoResult<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sends a password reset email.
  Future<RepoResult<void>> sendPasswordResetEmail(String email);

  /// Signs out the current user.
  Future<RepoResult<void>> signOut();

  /// Sends an email verification link to the currently signed-in user.
  Future<RepoResult<void>> sendEmailVerification();

  /// Reloads the currently signed-in user from Firebase Auth to refresh fields like `emailVerified`.
  Future<RepoResult<AuthUser?>> reloadUser();

  /// Re-authenticates the currently signed-in user with their password.
  Future<RepoResult<void>> reauthenticateWithPassword(String password);

  /// Permanently deletes the currently signed-in Firebase Auth user.
  Future<RepoResult<void>> deleteAccount();
}

/// Firebase Auth implementation of [AuthRepository].
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth? _customFirebaseAuth;

  FirebaseAuthRepository({FirebaseAuth? firebaseAuth})
      : _customFirebaseAuth = firebaseAuth;

  FirebaseAuth? get _auth {
    if (_customFirebaseAuth != null) return _customFirebaseAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  AuthUser? _toAuthUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      emailVerified: user.emailVerified,
    );
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    final auth = _auth;
    if (auth == null) {
      return Stream.value(null);
    }
    return auth.authStateChanges().map(_toAuthUser);
  }

  @override
  AuthUser? get currentUser => _toAuthUser(_auth?.currentUser);

  @override
  Future<RepoResult<AuthUser>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final auth = _auth;
    if (auth == null) {
      return const RepoResult.error('Authentication service is currently unavailable.');
    }

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return const RepoResult.error('Registration failed: no user returned.');
      }

      // Update Firebase Auth profile displayName
      if (displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
        await user.reload();
      }

      final updatedUser = auth.currentUser ?? user;
      return RepoResult.success(_toAuthUser(updatedUser)!);
    } on FirebaseAuthException catch (e, stack) {
      return RepoResult.error(AuthErrorMapper.mapCode(e.code), e, stack);
    } catch (e, stack) {
      return RepoResult.error(
        'Unexpected registration error. Please try again.',
        e,
        stack,
      );
    }
  }

  @override
  Future<RepoResult<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      return const RepoResult.error('Authentication service is currently unavailable.');
    }

    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return const RepoResult.error('Sign in failed: no user returned.');
      }

      return RepoResult.success(_toAuthUser(user)!);
    } on FirebaseAuthException catch (e, stack) {
      return RepoResult.error(AuthErrorMapper.mapCode(e.code), e, stack);
    } catch (e, stack) {
      return RepoResult.error(
        'Unexpected sign in error. Please try again.',
        e,
        stack,
      );
    }
  }

  @override
  Future<RepoResult<void>> sendPasswordResetEmail(String email) async {
    final auth = _auth;
    if (auth == null) {
      return const RepoResult.error('Authentication service is currently unavailable.');
    }

    try {
      await auth.sendPasswordResetEmail(email: email.trim());
      return const RepoResult.success(null);
    } on FirebaseAuthException catch (e, stack) {
      // If user-not-found, return success anyway to protect user privacy (neutral confirmation)
      if (e.code == 'user-not-found') {
        return const RepoResult.success(null);
      }
      return RepoResult.error(AuthErrorMapper.mapCode(e.code), e, stack);
    } catch (e, stack) {
      return RepoResult.error(
        'Unexpected error sending password reset. Please try again.',
        e,
        stack,
      );
    }
  }

  @override
  Future<RepoResult<void>> signOut() async {
    final auth = _auth;
    if (auth == null) {
      return const RepoResult.success(null);
    }

    try {
      await auth.signOut();
      return const RepoResult.success(null);
    } on FirebaseAuthException catch (e, stack) {
      return RepoResult.error(AuthErrorMapper.mapCode(e.code), e, stack);
    } catch (e, stack) {
      return RepoResult.error('Unexpected error signing out.', e, stack);
    }
  }

  @override
  Future<RepoResult<void>> sendEmailVerification() async {
    final auth = _auth;
    final user = auth?.currentUser;
    if (auth == null || user == null) {
      return const RepoResult.error('You must be signed in to verify your email.');
    }

    try {
      await user.sendEmailVerification();
      return const RepoResult.success(null);
    } on FirebaseAuthException catch (e, stack) {
      return RepoResult.error(AuthErrorMapper.mapCode(e.code), e, stack);
    } catch (e, stack) {
      return RepoResult.error(
        'Could not send verification email right now. Please try again.',
        e,
        stack,
      );
    }
  }

  @override
  Future<RepoResult<AuthUser?>> reloadUser() async {
    final auth = _auth;
    final user = auth?.currentUser;
    if (auth == null || user == null) {
      return const RepoResult.error('You are not signed in.');
    }

    try {
      await user.reload();
      return RepoResult.success(_toAuthUser(auth.currentUser));
    } on FirebaseAuthException catch (e, stack) {
      return RepoResult.error(AuthErrorMapper.mapCode(e.code), e, stack);
    } catch (e, stack) {
      return RepoResult.error(
        'Could not refresh your account status. Please try again.',
        e,
        stack,
      );
    }
  }

  @override
  Future<RepoResult<void>> reauthenticateWithPassword(String password) async {
    final auth = _auth;
    final user = auth?.currentUser;
    final email = user?.email;
    if (auth == null || user == null || email == null || email.isEmpty) {
      return const RepoResult.error('You must be signed in to confirm your password.');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return const RepoResult.success(null);
    } on FirebaseAuthException catch (e, stack) {
      return RepoResult.error(AuthErrorMapper.mapCode(e.code), e, stack);
    } catch (e, stack) {
      return RepoResult.error(
        'Could not verify your password. Please try again.',
        e,
        stack,
      );
    }
  }

  @override
  Future<RepoResult<void>> deleteAccount() async {
    final auth = _auth;
    final user = auth?.currentUser;
    if (auth == null || user == null) {
      return const RepoResult.error('You must be signed in to delete your account.');
    }

    try {
      await user.delete();
      return const RepoResult.success(null);
    } on FirebaseAuthException catch (e, stack) {
      return RepoResult.error(AuthErrorMapper.mapCode(e.code), e, stack);
    } catch (e, stack) {
      return RepoResult.error(
        'Could not delete your account right now. Please try again.',
        e,
        stack,
      );
    }
  }
}
