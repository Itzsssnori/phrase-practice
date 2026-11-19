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
}
