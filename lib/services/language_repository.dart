import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/language.dart';
import '../models/result.dart';

/// Abstract contract for language retrieval.
abstract interface class LanguageRepository {
  /// Fetches all active languages available for study or UI selection.
  Future<RepoResult<List<Language>>> getActiveLanguages({bool forceRefresh = false});
}

/// Cloud Firestore implementation of [LanguageRepository].
class FirestoreLanguageRepository implements LanguageRepository {
  final FirebaseFirestore? _customFirestore;
  List<Language>? _cachedLanguages;

  FirestoreLanguageRepository({FirebaseFirestore? firestore})
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
  Future<RepoResult<List<Language>>> getActiveLanguages({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedLanguages != null && _cachedLanguages!.isNotEmpty) {
      return RepoResult.success(_cachedLanguages!);
    }

    final db = _firestore;
    if (db == null) {
      return const RepoResult.error('Firebase not initialized.');
    }

    try {
      final snapshot = await db
          .collection('languages')
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        return const RepoResult.empty('No active languages found in database.');
      }

      final languages = snapshot.docs
          .map((doc) => Language.fromMap(doc.id, doc.data()))
          .toList();

      _cachedLanguages = languages;
      return RepoResult.success(languages);
    } on FirebaseException catch (e, stack) {
      return RepoResult.error(
        e.message ?? 'Firestore error while loading languages (${e.code})',
        e,
        stack,
      );
    } catch (e, stack) {
      return RepoResult.error('Unexpected error while loading languages: $e', e, stack);
    }
  }
}
