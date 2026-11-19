/// Minimal, immutable domain representation of an authenticated user.
class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;

  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          displayName == other.displayName;

  @override
  int get hashCode => Object.hash(uid, email, displayName);

  @override
  String toString() => 'AuthUser(uid: $uid, email: $email, displayName: $displayName)';
}
