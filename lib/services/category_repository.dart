import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../models/result.dart';

/// Abstract contract for category retrieval.
abstract interface class CategoryRepository {
  /// Fetches all active categories with titles resolved in [languageCode].
  Future<RepoResult<List<Category>>> getCategories(String languageCode, {bool forceRefresh = false});
}

/// Cloud Firestore implementation of [CategoryRepository].
class FirestoreCategoryRepository implements CategoryRepository {
  final FirebaseFirestore _firestore;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _cachedCategoryDocs;

  FirestoreCategoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<RepoResult<List<Category>>> getCategories(String languageCode, {bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cachedCategoryDocs != null && _cachedCategoryDocs!.isNotEmpty) {
        final categories = _cachedCategoryDocs!
            .map((doc) => Category.fromMap(doc.id, doc.data(), languageCode))
            .toList();
        return RepoResult.success(categories);
      }

      final snapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      if (snapshot.docs.isEmpty) {
        return const RepoResult.empty('No active categories found in database.');
      }

      _cachedCategoryDocs = snapshot.docs;
      final categories = snapshot.docs
          .map((doc) => Category.fromMap(doc.id, doc.data(), languageCode))
          .toList();

      return RepoResult.success(categories);
    } on FirebaseException catch (e, stack) {
      return RepoResult.error(
        e.message ?? 'Firestore error while loading categories (${e.code})',
        e,
        stack,
      );
    } catch (e, stack) {
      return RepoResult.error('Unexpected error while loading categories: $e', e, stack);
    }
  }
}
