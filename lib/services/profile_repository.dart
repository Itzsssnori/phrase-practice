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

  /// Saves or creates a full user profile document with merge.
  Future<RepoResult<void>> createOrUpdateProfile(UserProfile profile);
}

/// Cloud Firestore implementation of [ProfileRepository].
class FirestoreProfileRepository implements ProfileRepository {
  final FirebaseFirestore _firestore;

  FirestoreProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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
