import '../models/category.dart';
import '../models/language.dart';
import '../models/phrase.dart';
import '../models/result.dart';
import 'category_repository.dart';
import 'language_repository.dart';
import 'phrase_repository.dart';

/// Central data coordinator and in-memory cache for the browsing experience.
///
/// Ensures Firestore is queried once per app session for active phrases, categories,
/// and languages, so subsequent screen transitions (Home, Categories, CategoryPhrases,
/// PhraseStudy, Search) resolve instantly with zero additional database reads.
class BrowseDataService {
  static BrowseDataService instance = BrowseDataService();

  static void setMockInstance(BrowseDataService mock) {
    instance = mock;
  }

  LanguageRepository? _customLanguageRepo;
  CategoryRepository? _customCategoryRepo;
  PhraseRepository? _customPhraseRepo;

  LanguageRepository get _languageRepo => _customLanguageRepo ??= FirestoreLanguageRepository();
  CategoryRepository get _categoryRepo => _customCategoryRepo ??= FirestoreCategoryRepository();
  PhraseRepository get _phraseRepo => _customPhraseRepo ??= FirestorePhraseRepository();

  List<Language>? _cachedLanguages;
  List<Category>? _cachedCategories;
  String? _cachedCategoryLanguage;
  List<Phrase>? _cachedPhrases;

  BrowseDataService({
    LanguageRepository? languageRepo,
    CategoryRepository? categoryRepo,
    PhraseRepository? phraseRepo,
  })  : _customLanguageRepo = languageRepo,
        _customCategoryRepo = categoryRepo,
        _customPhraseRepo = phraseRepo;

  /// Fetches active languages, returning from in-memory cache when available.
  Future<RepoResult<List<Language>>> getLanguages({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedLanguages != null && _cachedLanguages!.isNotEmpty) {
      return RepoResult.success(_cachedLanguages!);
    }

    final result = await _languageRepo.getActiveLanguages(forceRefresh: forceRefresh);
    if (result.isSuccess) {
      _cachedLanguages = result.dataOrNull;
    }
    return result;
  }

  /// Fetches categories with localized names resolved in [nativeLanguageCode].
  Future<RepoResult<List<Category>>> getCategories(
    String nativeLanguageCode, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedCategories != null &&
        _cachedCategories!.isNotEmpty &&
        _cachedCategoryLanguage == nativeLanguageCode) {
      return RepoResult.success(_cachedCategories!);
    }

    // Ensure phrases are pre-loaded so category phrase counts can be populated
    if (_cachedPhrases == null) {
      await getAllPhrases(forceRefresh: forceRefresh);
    }

    final result = await _categoryRepo.getCategories(nativeLanguageCode, forceRefresh: forceRefresh);
    if (result.isSuccess && result.dataOrNull != null) {
      final rawCategories = result.dataOrNull!;
      // Attach accurate phrase counts from cached phrases
      final enrichedCategories = rawCategories.map((cat) {
        final count = getCategoryPhraseCount(cat.id);
        return Category(
          id: cat.id,
          sortOrder: cat.sortOrder,
          iconKey: cat.iconKey,
          isActive: cat.isActive,
          names: cat.names,
          title: cat.nameFor(nativeLanguageCode),
          phraseCount: count,
        );
      }).toList();

      _cachedCategories = enrichedCategories;
      _cachedCategoryLanguage = nativeLanguageCode;
      return RepoResult.success(enrichedCategories);
    }

    return result;
  }

  /// Fetches all active phrases across all categories and caches them in memory.
  Future<RepoResult<List<Phrase>>> getAllPhrases({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedPhrases != null && _cachedPhrases!.isNotEmpty) {
      return RepoResult.success(_cachedPhrases!);
    }

    final result = await _phraseRepo.getAllPhrases();
    if (result.isSuccess && result.dataOrNull != null) {
      _cachedPhrases = result.dataOrNull;
    }
    return result;
  }

  /// Fetches phrases for a specific category, resolved from in-memory cache.
  Future<RepoResult<List<Phrase>>> getPhrasesByCategory(
    String categoryId, {
    bool forceRefresh = false,
  }) async {
    // Populate cache if not loaded
    if (forceRefresh || _cachedPhrases == null) {
      final allResult = await getAllPhrases(forceRefresh: forceRefresh);
      if (allResult.isError) return allResult;
    }

    final all = _cachedPhrases ?? [];
    final categoryPhrases = all
        .where((p) => p.categoryId == categoryId && p.isActive)
        .toList();

    categoryPhrases.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (categoryPhrases.isEmpty) {
      return RepoResult.empty('No phrases found for category "$categoryId".');
    }

    return RepoResult.success(categoryPhrases);
  }

  /// Fetches a phrase by its slug, checking memory cache first before hitting repository.
  Future<RepoResult<Phrase>> getPhraseBySlug(String slug) async {
    if (_cachedPhrases != null) {
      final found = _cachedPhrases!.where((p) => p.id == slug).firstOrNull;
      if (found != null) {
        return RepoResult.success(found);
      }
    }

    // Try loading all phrases
    final allResult = await getAllPhrases();
    if (allResult.isSuccess && _cachedPhrases != null) {
      final found = _cachedPhrases!.where((p) => p.id == slug).firstOrNull;
      if (found != null) {
        return RepoResult.success(found);
      }
    }

    return _phraseRepo.getPhraseById(slug);
  }

  /// Returns the number of active phrases assigned to [categoryId].
  int getCategoryPhraseCount(String categoryId) {
    if (_cachedPhrases == null) return 0;
    return _cachedPhrases!.where((p) => p.categoryId == categoryId && p.isActive).length;
  }

  /// Performs local, debounced search against cached phrases matching keyword [query]
  /// in both [nativeLang] and [targetLang], ignoring case and diacritical accents.
  Future<RepoResult<List<Phrase>>> searchPhrases({
    required String query,
    String? categoryId,
    required String nativeLang,
    required String targetLang,
  }) async {
    final cleanQuery = normalize(query);

    // If cache not loaded yet, fetch all phrases once
    if (_cachedPhrases == null) {
      final loadResult = await getAllPhrases();
      if (loadResult.isError) return loadResult;
    }

    final all = _cachedPhrases ?? [];
    if (all.isEmpty) {
      return const RepoResult.empty('No phrases available.');
    }

    // If query is empty but a category is picked, return that category's phrases
    if (cleanQuery.isEmpty) {
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        final catMatches = all
            .where((p) => p.categoryId == categoryId && p.isActive)
            .toList();
        catMatches.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return RepoResult.success(catMatches);
      }
      return const RepoResult.empty('Type to search.');
    }

    final matches = all.where((phrase) {
      if (!phrase.isActive) return false;

      // Filter by category if category filter is active
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        if (phrase.categoryId != categoryId) return false;
      }

      // Check target language text
      final targetText = phrase.translationFor(targetLang)?.text;
      if (targetText != null && normalize(targetText).contains(cleanQuery)) {
        return true;
      }

      // Check native language text
      final nativeText = phrase.translationFor(nativeLang)?.text ?? phrase.originalText;
      if (normalize(nativeText).contains(cleanQuery)) {
        return true;
      }

      // Check pronunciation respelling
      final pronunciation = phrase.translationFor(targetLang)?.pronunciation;
      if (pronunciation != null && normalize(pronunciation).contains(cleanQuery)) {
        return true;
      }

      // Check meaning note
      final note = phrase.translationFor(targetLang)?.meaningNote ??
          phrase.translationFor(nativeLang)?.meaningNote;
      if (note != null && normalize(note).contains(cleanQuery)) {
        return true;
      }

      // Check phrase slug
      if (normalize(phrase.id).contains(cleanQuery)) {
        return true;
      }

      return false;
    }).toList();

    matches.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (matches.isEmpty) {
      return RepoResult.empty('No phrases found matching "$query".');
    }

    return RepoResult.success(matches);
  }

  /// Clears in-memory cache to force re-fetch from Firestore.
  void clearCache() {
    _cachedLanguages = null;
    _cachedCategories = null;
    _cachedCategoryLanguage = null;
    _cachedPhrases = null;
    _phraseRepo.invalidateSearchCache();
  }

  /// Normalizes strings for accent-insensitive and case-insensitive comparison.
  static String normalize(String input) {
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
