import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../models/result.dart';

/// Abstract contract for category retrieval.
abstract interface class CategoryRepository {
  /// Fetches all active categories with titles resolved in [languageCode].
  Future<RepoResult<List<Category>>> getCategories(String languageCode);
}

/// Cloud Firestore implementation of [CategoryRepository].
class FirestoreCategoryRepository implements CategoryRepository {
  final FirebaseFirestore _firestore;

  FirestoreCategoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<RepoResult<List<Category>>> getCategories(String languageCode) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      if (snapshot.docs.isEmpty) {
        return const RepoResult.empty('No active categories found in database.');
      }

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
