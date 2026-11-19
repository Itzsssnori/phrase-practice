import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/phrase.dart';
import '../models/result.dart';

/// Abstract contract for phrase queries and in-memory search.
abstract interface class PhraseRepository {
  /// Fetches all active phrases across all categories, ordered by sortOrder.
  Future<RepoResult<List<Phrase>>> getAllPhrases();

  /// Fetches active phrases belonging to [categoryId], ordered by sortOrder.
  Future<RepoResult<List<Phrase>>> getPhrasesByCategory(String categoryId);

  /// Fetches a single phrase by its document slug [id].
  Future<RepoResult<Phrase>> getPhraseById(String id);

  /// Searches active phrases locally against cached data using keyword [query] in [languageCode].
  Future<RepoResult<List<Phrase>>> searchPhrases(String query, String languageCode);

  /// Clears the in-memory search cache so next search re-fetches from Firestore.
  void invalidateSearchCache();
}

/// Cloud Firestore implementation of [PhraseRepository] with in-memory caching for local search.
class FirestorePhraseRepository implements PhraseRepository {
  final FirebaseFirestore? _customFirestore;

  // In-memory cache for search operations
  List<Phrase>? _cachedActivePhrases;

  FirestorePhraseRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  @override
  Future<RepoResult<List<Phrase>>> getAllPhrases() async {
    try {
      if (_cachedActivePhrases != null) {
        return RepoResult.success(_cachedActivePhrases!);
      }

      final snapshot = await _firestore
          .collection('phrases')
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        return const RepoResult.empty('No active phrases found in database.');
      }

      final phrases = snapshot.docs
          .map((doc) => Phrase.fromMap(doc.id, doc.data()))
          .toList();

      phrases.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _cachedActivePhrases = phrases;
      return RepoResult.success(phrases);
    } on FirebaseException catch (e, stack) {
      return RepoResult.error(
        e.message ?? 'Firestore error fetching phrases (${e.code})',
        e,
        stack,
      );
    } catch (e, stack) {
      return RepoResult.error('Unexpected error fetching phrases: $e', e, stack);
    }
  }

  @override
  Future<RepoResult<List<Phrase>>> getPhrasesByCategory(String categoryId) async {
    try {
      // Reuse cached phrases if already loaded into memory
      if (_cachedActivePhrases != null) {
        final matches = _cachedActivePhrases!
            .where((p) => p.categoryId == categoryId && p.isActive)
            .toList();
        matches.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        if (matches.isEmpty) {
          return RepoResult.empty('No phrases found for category "$categoryId".');
        }
        return RepoResult.success(matches);
      }

      final snapshot = await _firestore
          .collection('phrases')
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      if (snapshot.docs.isEmpty) {
        return RepoResult.empty('No phrases found for category "$categoryId".');
      }

      final phrases = snapshot.docs
          .map((doc) => Phrase.fromMap(doc.id, doc.data()))
          .toList();

      return RepoResult.success(phrases);
    } on FirebaseException catch (e, stack) {
      return RepoResult.error(
        e.message ?? 'Firestore error fetching category phrases (${e.code})',
        e,
        stack,
      );
    } catch (e, stack) {
      return RepoResult.error('Unexpected error fetching category phrases: $e', e, stack);
    }
  }

  @override
  Future<RepoResult<Phrase>> getPhraseById(String id) async {
    try {
      if (_cachedActivePhrases != null) {
        final cached = _cachedActivePhrases!.where((p) => p.id == id).firstOrNull;
        if (cached != null) {
          return RepoResult.success(cached);
        }
      }

      final doc = await _firestore.collection('phrases').doc(id).get();

      if (!doc.exists || doc.data() == null) {
        return RepoResult.empty('Phrase "$id" does not exist.');
      }

      final phrase = Phrase.fromMap(doc.id, doc.data()!);
      return RepoResult.success(phrase);
    } on FirebaseException catch (e, stack) {
      return RepoResult.error(
        e.message ?? 'Firestore error fetching phrase "$id" (${e.code})',
        e,
        stack,
      );
    } catch (e, stack) {
      return RepoResult.error('Unexpected error fetching phrase: $e', e, stack);
    }
  }

  @override
  Future<RepoResult<List<Phrase>>> searchPhrases(String query, String languageCode) async {
    final cleanQuery = _normalize(query);
    if (cleanQuery.isEmpty) {
      return const RepoResult.empty('Enter a search query.');
    }

    try {
      // 1. Ensure active phrases are loaded into memory cache
      if (_cachedActivePhrases == null) {
        final snapshot = await _firestore
            .collection('phrases')
            .where('isActive', isEqualTo: true)
            .get();

        _cachedActivePhrases = snapshot.docs
            .map((doc) => Phrase.fromMap(doc.id, doc.data()))
            .toList();
      }

      final allPhrases = _cachedActivePhrases ?? [];
      if (allPhrases.isEmpty) {
        return const RepoResult.empty('No active phrases in database.');
      }

      // 2. Filter locally: case-insensitive, accent-insensitive
      final matches = allPhrases.where((phrase) {
        // Match target language translation text
        final targetText = phrase.translationFor(languageCode)?.text;
        if (targetText != null && _normalize(targetText).contains(cleanQuery)) {
          return true;
        }

        // Match English / primary original text
        final englishText = phrase.translationFor('en')?.text ?? phrase.originalText;
        if (_normalize(englishText).contains(cleanQuery)) {
          return true;
        }

        // Match explanation / meaning note
        final note = phrase.translationFor(languageCode)?.meaningNote ??
            phrase.translationFor('en')?.meaningNote;
        if (note != null && _normalize(note).contains(cleanQuery)) {
          return true;
        }

        // Match document slug
        if (_normalize(phrase.id).contains(cleanQuery)) {
          return true;
        }

        return false;
      }).toList();

      if (matches.isEmpty) {
        return RepoResult.empty('No phrases found matching "$query".');
      }

      return RepoResult.success(matches);
    } on FirebaseException catch (e, stack) {
      return RepoResult.error(
        e.message ?? 'Firestore error while searching phrases (${e.code})',
        e,
        stack,
      );
    } catch (e, stack) {
      return RepoResult.error('Unexpected error during search: $e', e, stack);
    }
  }

  @override
  void invalidateSearchCache() {
    _cachedActivePhrases = null;
  }

  /// Normalizes strings by converting to lowercase and stripping common diacritical marks.
  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâãå]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöôõ]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .trim();
  }
}
