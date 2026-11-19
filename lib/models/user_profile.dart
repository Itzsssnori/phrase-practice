import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile entity representing user configuration and study preferences.
class UserProfile {
  final String uid;
  final String? displayName;
  final String nativeLanguageCode;
  final String targetLanguageCode;
  final Map<String, dynamic> preferences;
  final DateTime? createdAt;

  const UserProfile({
    required this.uid,
    this.displayName,
    this.nativeLanguageCode = 'en',
    this.targetLanguageCode = 'es',
    this.preferences = const {},
    this.createdAt,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    DateTime? parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    } else if (rawCreatedAt is int) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
    }

    return UserProfile(
      uid: uid,
      displayName: (map['displayName'] as String?)?.trim(),
      nativeLanguageCode: (map['nativeLanguageCode'] as String?)?.trim() ?? 'en',
      targetLanguageCode: (map['targetLanguageCode'] as String?)?.trim() ?? 'es',
      preferences: (map['preferences'] as Map<String, dynamic>?) ?? {},
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'nativeLanguageCode': nativeLanguageCode,
      'targetLanguageCode': targetLanguageCode,
      'preferences': preferences,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? nativeLanguageCode,
    String? targetLanguageCode,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      nativeLanguageCode: nativeLanguageCode ?? this.nativeLanguageCode,
      targetLanguageCode: targetLanguageCode ?? this.targetLanguageCode,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserProfile && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'UserProfile($uid, native: $nativeLanguageCode, target: $targetLanguageCode)';
}
