import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/result.dart';
import '../models/user_profile.dart';

/// Abstract contract for reading and modifying user profile settings.
abstract interface class ProfileRepository {
  /// Retrieves the user profile document for [uid].
  Future<RepoResult<UserProfile>> getUserProfile(String uid);

  /// Updates the user's active native and target language codes.
  Future<RepoResult<void>> updateUserLanguages(
    String uid, {
    required String nativeLanguageCode,
    required String targetLanguageCode,
  });

  /// Merges new user preferences (such as recall mode, font size) into the user document.
  Future<RepoResult<void>> updateUserPreferences(
    String uid,
    Map<String, dynamic> preferences,
  );

  /// Creates a initial user profile document strictly matching the allowed fields in firestore.rules.
  Future<RepoResult<UserProfile>> createProfile({
    required String uid,
    String? displayName,
    required String nativeLanguageCode,
    required String targetLanguageCode,
  });

  /// Saves or creates a full user profile document with merge.
  Future<RepoResult<void>> createOrUpdateProfile(UserProfile profile);
}

/// Cloud Firestore implementation of [ProfileRepository].
class FirestoreProfileRepository implements ProfileRepository {
  final FirebaseFirestore? _customFirestore;

  FirestoreProfileRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  @override
  Future<RepoResult<UserProfile>> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists || doc.data() == null) {
        return RepoResult.empty('Profile for user "$uid" does not exist.');
      }

      final profile = UserProfile.fromMap(doc.id, doc.data()!);
      return RepoResult.success(profile);
    } on FirebaseException catch (e, stack) {
      return RepoResult.error(
        e.message ?? 'Firestore error fetching profile for "$uid" (${e.code})',
        e,
        stack,
      );
    } catch (e, stack) {
      return RepoResult.error('Unexpected error fetching profile: $e', e, stack);
    }
  }

  @override
  Future<RepoResult<void>> updateUserLanguages(
    String uid, {
    required String nativeLanguageCode,
    required String targetLanguageCode,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'nativeLanguageCode': nativeLanguageCode,
        'targetLanguageCode': targetLanguageCode,
      }, SetOptions(merge: true));

      return const RepoResult.success(null);
    } on FirebaseException catch (e, stack) {
      return RepoResult.error(
        e.message ?? 'Firestore error updating languages (${e.code})',
        e,
        stack,
      );
    } catch (e, stack) {
      return RepoResult.error('Unexpected error updating languages: $e', e, stack);
    }
  }

  @override
  Future<RepoResult<void>> updateUserPreferences(
    String uid,
    Map<String, dynamic> preferences,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'preferences': preferences,
      }, SetOptions(merge: true));

      return const RepoResult.success(null);
    } on FirebaseException catch (e, stack) {
      return RepoResult.error(
        e.message ?? 'Firestore error updating preferences (${e.code})',
        e,
        stack,
      );
    } catch (e, stack) {
      return RepoResult.error('Unexpected error updating preferences: $e', e, stack);
    }
  }

  @override
  Future<RepoResult<UserProfile>> createProfile({
    required String uid,
    String? displayName,
    required String nativeLanguageCode,
    required String targetLanguageCode,
  }) async {
    try {
      final cleanName = displayName?.trim();
      final data = <String, dynamic>{
        if (cleanName != null && cleanName.isNotEmpty) 'displayName': cleanName,
        'nativeLanguageCode': nativeLanguageCode,
        'targetLanguageCode': targetLanguageCode,
        'preferences': <String, dynamic>{},
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(uid).set(data);

      final profile = UserProfile(
        uid: uid,
        displayName: cleanName,
        nativeLanguageCode: nativeLanguageCode,
        targetLanguageCode: targetLanguageCode,
        preferences: const {},
        createdAt: DateTime.now(),
      );

      return RepoResult.success(profile);
    } on FirebaseException catch (e, stack) {
      return RepoResult.error(
        e.message ?? 'Firestore error creating profile (${e.code})',
        e,
        stack,
      );
    } catch (e, stack) {
      return RepoResult.error('Unexpected error creating profile: $e', e, stack);
    }
  }

  @override
  Future<RepoResult<void>> createOrUpdateProfile(UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(profile.uid).set(
            profile.toMap(),
            SetOptions(merge: true),
          );

      return const RepoResult.success(null);
    } on FirebaseException catch (e, stack) {
      return RepoResult.error(
        e.message ?? 'Firestore error creating/updating profile (${e.code})',
        e,
        stack,
      );
    } catch (e, stack) {
      return RepoResult.error('Unexpected error saving profile: $e', e, stack);
    }
  }
}
