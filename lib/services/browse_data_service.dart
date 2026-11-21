import '../models/category.dart';
import '../models/language.dart';
import '../models/phrase.dart';
import '../models/result.dart';
import 'category_repository.dart';
import 'language_repository.dart';
import 'phrase_repository.dart';
import 'search_normalizer.dart';

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

  /// Fetches active languages ordered by sortOrder, returning from in-memory cache when available.
  Future<RepoResult<List<Language>>> getLanguages({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedLanguages != null && _cachedLanguages!.isNotEmpty) {
      return RepoResult.success(_cachedLanguages!);
    }

    final result = await _languageRepo.getActiveLanguages(forceRefresh: forceRefresh);
    if (result.isSuccess && result.dataOrNull != null) {
      final activeSorted = result.dataOrNull!
          .where((l) => l.isActive)
          .toList()
        ..sort((a, b) => a.effectiveSortOrder.compareTo(b.effectiveSortOrder));
      _cachedLanguages = activeSorted;
      return RepoResult.success(activeSorted);
    }
    return result;
  }

  /// Fetches active categories with localized names resolved in [nativeLanguageCode].
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
      final rawCategories = result.dataOrNull!.where((c) => c.isActive).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      // Attach accurate phrase counts from cached phrases while preserving group & priority
      final enrichedCategories = rawCategories.map((cat) {
        final count = getCategoryPhraseCount(cat.id);
        return cat.copyWith(
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
  /// in both [nativeLang] and [targetLang], applying per-script normalization rules.
  Future<RepoResult<List<Phrase>>> searchPhrases({
    required String query,
    String? categoryId,
    required String nativeLang,
    required String targetLang,
  }) async {
    final trimmedQuery = query.trim();

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
    if (trimmedQuery.isEmpty) {
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

      // 1. Check target language text using target language's script rules
      final targetText = phrase.translationFor(targetLang)?.text;
      if (targetText != null &&
          SearchNormalizer.matchesText(
            text: targetText,
            query: trimmedQuery,
            languageCode: targetLang,
          )) {
        return true;
      }

      // 2. Check native language text using native language's script rules
      final nativeText =
          phrase.translationFor(nativeLang)?.text ?? phrase.originalText;
      if (SearchNormalizer.matchesText(
        text: nativeText,
        query: trimmedQuery,
        languageCode: nativeLang,
      )) {
        return true;
      }

      // 3. Check pronunciation (always Latin script: Respelling, Pinyin, Romaji, etc.)
      final pronunciation = phrase.translationFor(targetLang)?.pronunciation;
      if (pronunciation != null &&
          SearchNormalizer.matchesPronunciation(
            pronunciation: pronunciation,
            query: trimmedQuery,
          )) {
        return true;
      }

      // 4. Check meaning notes (always written in English / Latin script)
      final targetNote = phrase.translationFor(targetLang)?.meaningNote;
      if (targetNote != null &&
          SearchNormalizer.matchesText(
            text: targetNote,
            query: trimmedQuery,
            languageCode: 'en',
          )) {
        return true;
      }
      final nativeNote = phrase.translationFor(nativeLang)?.meaningNote;
      if (nativeNote != null &&
          SearchNormalizer.matchesText(
            text: nativeNote,
            query: trimmedQuery,
            languageCode: 'en',
          )) {
        return true;
      }

      // 5. Check phrase slug (Latin script)
      if (SearchNormalizer.matchesPronunciation(
        pronunciation: phrase.id,
        query: trimmedQuery,
      )) {
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

  /// Normalizes strings for comparison using per-script rules (defaults to Latin when [languageCode] is omitted).
  static String normalize(
    String input, {
    String? languageCode,
    String? script,
  }) {
    return SearchNormalizer.normalize(
      input,
      languageCode: languageCode,
      script: script,
    );
  }
}
