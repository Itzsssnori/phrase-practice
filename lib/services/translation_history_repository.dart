import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/result.dart';
import '../models/translation_entry.dart';

/// Abstract contract for reading and modifying a signed-in user's private
/// translation history at `users/{uid}/translationHistory/{autoId}`.
abstract interface class TranslationHistoryRepository {
  /// Loads the most recent [limit] (default 50) translations ordered by `createdAt` descending.
  Future<RepoResult<List<TranslationHistoryItem>>> getRecentHistory(
    String uid, {
    int limit = 50,
  });

  /// Saves one completed translation document with only the allowed fields.
  Future<RepoResult<TranslationHistoryItem>> saveTranslation(
    String uid,
    TranslationResult result,
  );

  /// Updates the `isSaved` flag for a single translation history entry.
  Future<RepoResult<void>> setSaved(String uid, String id, bool isSaved);

  /// Deletes a single translation history entry.
  Future<RepoResult<void>> deleteOne(String uid, String id);

  /// Deletes all translation history entries in batches of up to 500.
  Future<RepoResult<void>> deleteAll(String uid);
}

/// Cloud Firestore implementation of [TranslationHistoryRepository].
class FirestoreTranslationHistoryRepository implements TranslationHistoryRepository {
  final FirebaseFirestore? _customFirestore;

  FirestoreTranslationHistoryRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>> _collection(FirebaseFirestore db, String uid) {
    return db.collection('users').doc(uid).collection('translationHistory');
  }

  @override
  Future<RepoResult<List<TranslationHistoryItem>>> getRecentHistory(
    String uid, {
    int limit = 50,
  }) async {
    try {
      final db = _firestore;
      if (db == null) {
        return const RepoResult.error(
          'History is currently unavailable.',
          'firestore-unavailable',
        );
      }

      final snapshot = await _collection(db, uid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final items = snapshot.docs
          .map((doc) => TranslationHistoryItem.fromMap(doc.id, doc.data()))
          .toList();

      return RepoResult.success(items);
    } catch (e) {
      return const RepoResult.error(
        'Could not load translation history. Please try again.',
        'load-history-failed',
      );
    }
  }

  @override
  Future<RepoResult<TranslationHistoryItem>> saveTranslation(
    String uid,
    TranslationResult result,
  ) async {
    try {
      final db = _firestore;
      if (db == null) {
        return const RepoResult.error(
          'Could not save to history.',
          'firestore-unavailable',
        );
      }

      final docRef = _collection(db, uid).doc();
      final payload = TranslationHistoryItem.toCreatePayload(result);
      await docRef.set(payload);

      final item = TranslationHistoryItem(
        id: docRef.id,
        inputText: result.inputText,
        sourceLanguageCode: result.sourceLanguageCode,
        targetLanguageCode: result.targetLanguageCode,
        translatedText: result.translatedText,
        pronunciation: result.pronunciation,
        exampleSentence: result.exampleSentence,
        exampleTranslation: result.exampleTranslation,
        note: result.note,
        isSaved: false,
        createdAt: DateTime.now(),
      );

      return RepoResult.success(item);
    } catch (e) {
      return const RepoResult.error(
        'Could not save to history.',
        'save-history-failed',
      );
    }
  }

  @override
  Future<RepoResult<void>> setSaved(String uid, String id, bool isSaved) async {
    try {
      final db = _firestore;
      if (db == null) {
        return const RepoResult.error(
          'Could not update saved state.',
          'firestore-unavailable',
        );
      }

      await _collection(db, uid).doc(id).update({'isSaved': isSaved});
      return const RepoResult.success(null);
    } catch (e) {
      return const RepoResult.error(
        'Could not update saved state. Please try again.',
        'update-saved-failed',
      );
    }
  }

  @override
  Future<RepoResult<void>> deleteOne(String uid, String id) async {
    try {
      final db = _firestore;
      if (db == null) {
        return const RepoResult.error(
          'Could not delete history item.',
          'firestore-unavailable',
        );
      }

      await _collection(db, uid).doc(id).delete();
      return const RepoResult.success(null);
    } catch (e) {
      return const RepoResult.error(
        'Could not delete history item. Please try again.',
        'delete-one-failed',
      );
    }
  }

  @override
  Future<RepoResult<void>> deleteAll(String uid) async {
    const int batchLimit = 500;
    try {
      final db = _firestore;
      if (db == null) {
        return const RepoResult.error(
          'Could not clear history.',
          'firestore-unavailable',
        );
      }

      final col = _collection(db, uid);
      while (true) {
        final snapshot = await col.limit(batchLimit).get();
        if (snapshot.docs.isEmpty) break;

        final batch = db.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        if (snapshot.docs.length < batchLimit) break;
      }

      return const RepoResult.success(null);
    } catch (e) {
      return const RepoResult.error(
        'Could not clear translation history. Please try again.',
        'delete-all-failed',
      );
    }
  }
}
