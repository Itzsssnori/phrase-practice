import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/result.dart';

/// Abstract contract for managing user-specific phrase interactions:
/// bookmarked favorites, mastered/learned phrases, and recently studied phrases.
abstract interface class UserPhraseRepository {
  /// Loads all favorited phrase slugs for [uid], newest first.
  Future<RepoResult<List<String>>> getFavoritePhraseIds(String uid);

  /// Bookmarks a phrase as a favorite.
  Future<RepoResult<void>> addFavorite(String uid, String phraseSlug);

  /// Removes a phrase from favorites.
  Future<RepoResult<void>> removeFavorite(String uid, String phraseSlug);

  /// Loads all learned phrase slugs for [uid], partitioned by target language code.
  Future<RepoResult<Map<String, Set<String>>>> getAllLearnedPhraseIds(String uid);

  /// Marks a phrase as learned for a specific target language.
  Future<RepoResult<void>> markPhraseLearned(
    String uid,
    String phraseSlug,
    String targetLanguageCode,
  );

  /// Unmarks a phrase as learned for a specific target language.
  Future<RepoResult<void>> unmarkPhraseLearned(
    String uid,
    String phraseSlug,
    String targetLanguageCode,
  );

  /// Records a study visit for a phrase with a timestamp.
  Future<RepoResult<void>> recordRecentView(String uid, String phraseSlug);

  /// Loads recently viewed phrase slugs for [uid], ordered by last view time descending.
  Future<RepoResult<List<String>>> getRecentPhraseIds(String uid, {int limit = 20});
}

/// Cloud Firestore implementation of [UserPhraseRepository].
class FirestoreUserPhraseRepository implements UserPhraseRepository {
  final FirebaseFirestore? _customFirestore;

  FirestoreUserPhraseRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<RepoResult<List<String>>> getFavoritePhraseIds(String uid) async {
    final db = _firestore;
    if (db == null) {
      return const RepoResult.error('Database connection unavailable.');
    }

    try {
      final snapshot = await db
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .get();

      final ids = snapshot.docs.map((doc) => doc.id).toList();
      return RepoResult.success(ids);
    } on FirebaseException catch (e, stack) {
      return RepoResult.error(
        e.message ?? 'Firestore error fetching favorites (${e.code})',
        e,
        stack,
      );
    } catch (e, stack) {
      return RepoResult.error('Unexpected error loading favorites: $e', e, stack);
    }
  }

  @override
  Future<RepoResult<void>> addFavorite(String uid, String phraseSlug) async {
    final db = _firestore;
    if (db == null) {
      return const RepoResult.error('Database connection unavailable.');
    }

    try {
      await db
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .doc(phraseSlug)
          .set({
        'addedAt': FieldValue.serverTimestamp(),
      });
      return const RepoResult.success(null);
    } on FirebaseException catch (e, stack) {
      return RepoResult.error(
        e.message ?? 'Firestore error adding favorite (${e.code})',
        e,
        stack,
      );
    } catch (e, stack) {
      return RepoResult.error('Unexpected error adding favorite: $e', e, stack);
    }
  }

  @override
  Future<RepoResult<void>> removeFavorite(String uid, String phraseSlug) async {
    final db = _firestore;
    if (db == null) {
      return const RepoResult.error('Database connection unavailable.');
    }

    try {
      await db
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .doc(phraseSlug)
          .delete();
      return const RepoResult.success(null);
    } on FirebaseException catch (e, stack) {
      return RepoResult.error(
        e.message ?? 'Firestore error removing favorite (${e.code})',
        e,
        stack,
      );
    } catch (e, stack) {
      return RepoResult.error('Unexpected error removing favorite: $e', e, stack);
    }
  }

  @override
  Future<RepoResult<Map<String, Set<String>>>> getAllLearnedPhraseIds(String uid) async {
    final db = _firestore;
    if (db == null) {
      return const RepoResult.error('Database connection unavailable.');
    }

    try {
      final snapshot = await db
          .collection('users')
          .doc(uid)
          .collection('learnedPhrases')
          .get();

      final map = <String, Set<String>>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final phraseId = (data['phraseId'] as String?) ?? doc.id.split('__').firstOrNull;
        final langCode = (data['targetLanguageCode'] as String?) ??
            (doc.id.contains('__') ? doc.id.split('__').lastOrNull : null);

        if (phraseId != null && phraseId.isNotEmpty && langCode != null && langCode.isNotEmpty) {
          map.putIfAbsent(langCode, () => <String>{}).add(phraseId);
        }
      }
      return RepoResult.success(map);
    } on FirebaseException catch (e, stack) {
      return RepoResult.error(
        e.message ?? 'Firestore error fetching learned phrases (${e.code})',
        e,
        stack,
      );
    } catch (e, stack) {
      return RepoResult.error('Unexpected error loading learned phrases: $e', e, stack);
    }
  }

  @override
  Future<RepoResult<void>> markPhraseLearned(
    String uid,
    String phraseSlug,
    String targetLanguageCode,
  ) async {
    final db = _firestore;
    if (db == null) {
      return const RepoResult.error('Database connection unavailable.');
    }

    try {
      final docId = '${phraseSlug}__$targetLanguageCode';
      await db
          .collection('users')
          .doc(uid)
          .collection('learnedPhrases')
          .doc(docId)
          .set({
        'phraseId': phraseSlug,
        'targetLanguageCode': targetLanguageCode,
        'learnedAt': FieldValue.serverTimestamp(),
      });
      return const RepoResult.success(null);
    } on FirebaseException catch (e, stack) {
      return RepoResult.error(
        e.message ?? 'Firestore error marking phrase learned (${e.code})',
        e,
        stack,
      );
    } catch (e, stack) {
      return RepoResult.error('Unexpected error marking phrase learned: $e', e, stack);
    }
  }

  @override
  Future<RepoResult<void>> unmarkPhraseLearned(
    String uid,
    String phraseSlug,
    String targetLanguageCode,
  ) async {
    final db = _firestore;
    if (db == null) {
      return const RepoResult.error('Database connection unavailable.');
    }

    try {
      final docId = '${phraseSlug}__$targetLanguageCode';
      await db
          .collection('users')
          .doc(uid)
          .collection('learnedPhrases')
          .doc(docId)
          .delete();
      return const RepoResult.success(null);
    } on FirebaseException catch (e, stack) {
      return RepoResult.error(
        e.message ?? 'Firestore error unmarking phrase learned (${e.code})',
        e,
        stack,
      );
    } catch (e, stack) {
      return RepoResult.error('Unexpected error unmarking phrase learned: $e', e, stack);
    }
  }

  @override
  Future<RepoResult<void>> recordRecentView(String uid, String phraseSlug) async {
    final db = _firestore;
    if (db == null) {
      return const RepoResult.error('Database connection unavailable.');
    }

    try {
      await db
          .collection('users')
          .doc(uid)
          .collection('recentPhrases')
          .doc(phraseSlug)
          .set({
        'lastViewedAt': FieldValue.serverTimestamp(),
      });
      return const RepoResult.success(null);
    } on FirebaseException catch (e, stack) {
      return RepoResult.error(
        e.message ?? 'Firestore error recording recent phrase view (${e.code})',
        e,
        stack,
      );
    } catch (e, stack) {
      return RepoResult.error('Unexpected error recording recent phrase view: $e', e, stack);
    }
  }

  @override
  Future<RepoResult<List<String>>> getRecentPhraseIds(String uid, {int limit = 20}) async {
    final db = _firestore;
    if (db == null) {
      return const RepoResult.error('Database connection unavailable.');
    }

    try {
      final snapshot = await db
          .collection('users')
          .doc(uid)
          .collection('recentPhrases')
          .orderBy('lastViewedAt', descending: true)
          .limit(limit)
          .get();

      final ids = snapshot.docs.map((doc) => doc.id).toList();
      return RepoResult.success(ids);
    } on FirebaseException catch (e, stack) {
      return RepoResult.error(
        e.message ?? 'Firestore error loading recent phrases (${e.code})',
        e,
        stack,
      );
    } catch (e, stack) {
      return RepoResult.error('Unexpected error loading recent phrases: $e', e, stack);
    }
  }
}
