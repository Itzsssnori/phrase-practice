/// Minimal, immutable domain representation of an authenticated user.
class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool emailVerified;

  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.emailVerified = false,
  });

  AuthUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? emailVerified,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          displayName == other.displayName &&
          emailVerified == other.emailVerified;

  @override
  int get hashCode => Object.hash(uid, email, displayName, emailVerified);

  @override
  String toString() =>
      'AuthUser(uid: $uid, email: $email, displayName: $displayName, emailVerified: $emailVerified)';
}
