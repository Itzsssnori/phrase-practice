import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/phrase.dart';
import '../models/result.dart';
import 'auth_controller.dart';
import 'user_phrase_repository.dart';

/// Central state manager for authenticated user interactions with phrases:
/// favorites, learned phrases per target language, and recently studied phrases.
class UserPhraseController extends ChangeNotifier {
  final UserPhraseRepository _repository;
  final AuthController? authController;

  String? _currentUid;
  bool _isLoading = false;
  String? _errorMessage;

  // In-memory caches for fast, zero-delay UI rendering
  final List<String> _favoriteIds = [];
  final Set<String> _favoriteSet = {};
  final Map<String, Set<String>> _learnedPhraseIdsByLanguage = {};
  final List<String> _recentPhraseIds = [];

  // In-flight operation guards to ignore repeated double taps
  final Set<String> _inFlightFavoriteOperations = {};
  final Set<String> _inFlightLearnedOperations = {};

  UserPhraseController({
    UserPhraseRepository? repository,
    this.authController,
  }) : _repository = repository ?? FirestoreUserPhraseRepository() {
    _init();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<String> get favoritePhraseIds => List.unmodifiable(_favoriteIds);
  List<String> get recentPhraseIds => List.unmodifiable(_recentPhraseIds);

  void _init() {
    if (authController != null) {
      authController!.addListener(_onAuthChanged);
      _onAuthChanged();
    }
  }

  void _onAuthChanged() {
    final user = authController?.user;
    if (user != null && authController!.isSignedIn) {
      if (_currentUid != user.uid) {
        _currentUid = user.uid;
        loadForUser(user.uid);
      }
    } else {
      if (_currentUid != null || _favoriteIds.isNotEmpty || _learnedPhraseIdsByLanguage.isNotEmpty) {
        clear();
      }
    }
  }

  /// Clears all user-specific phrase state immediately (e.g. on sign out).
  void clear() {
    _currentUid = null;
    _favoriteIds.clear();
    _favoriteSet.clear();
    _learnedPhraseIdsByLanguage.clear();
    _recentPhraseIds.clear();
    _inFlightFavoriteOperations.clear();
    _inFlightLearnedOperations.clear();
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// One-time read loading favorites, learned phrases, and recent phrases for [uid].
  Future<void> loadForUser(String uid) async {
    _currentUid = uid;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getFavoritePhraseIds(uid),
        _repository.getAllLearnedPhraseIds(uid),
        _repository.getRecentPhraseIds(uid, limit: 20),
      ]);

      if (_currentUid != uid) return; // User switched while loading

      final favResult = results[0] as RepoResult<List<String>>;
      final learnedResult = results[1] as RepoResult<Map<String, Set<String>>>;
      final recentResult = results[2] as RepoResult<List<String>>;

      if (favResult.isError || learnedResult.isError || recentResult.isError) {
        _errorMessage = favResult.errorMessageOrNull ??
            learnedResult.errorMessageOrNull ??
            recentResult.errorMessageOrNull ??
            'Failed to load study data.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _favoriteIds.clear();
      _favoriteSet.clear();
      if (favResult.dataOrNull != null) {
        _favoriteIds.addAll(favResult.dataOrNull!);
        _favoriteSet.addAll(favResult.dataOrNull!);
      }

      _learnedPhraseIdsByLanguage.clear();
      if (learnedResult.dataOrNull != null) {
        for (final entry in learnedResult.dataOrNull!.entries) {
          _learnedPhraseIdsByLanguage[entry.key] = Set<String>.from(entry.value);
        }
      }

      _recentPhraseIds.clear();
      if (recentResult.dataOrNull != null) {
        _recentPhraseIds.addAll(recentResult.dataOrNull!);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (_currentUid != uid) return;
      _errorMessage = 'Failed to load user phrases: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Checks if [phraseSlug] is marked as favorite.
  bool isFavorite(String phraseSlug) {
    return _favoriteSet.contains(phraseSlug);
  }

  /// Checks if [phraseSlug] is marked as learned for [targetLanguageCode].
  bool isLearned(String phraseSlug, String targetLanguageCode) {
    return _learnedPhraseIdsByLanguage[targetLanguageCode]?.contains(phraseSlug) ?? false;
  }

  /// Computes the number of phrases in [categoryPhrases] that have been learned
  /// in [targetLanguageCode].
  int getLearnedCountForCategory(
    String categoryId,
    List<Phrase> categoryPhrases,
    String targetLanguageCode,
  ) {
    final learnedSet = _learnedPhraseIdsByLanguage[targetLanguageCode];
    if (learnedSet == null || learnedSet.isEmpty) return 0;

    int count = 0;
    for (final phrase in categoryPhrases) {
      if (phrase.categoryId == categoryId && learnedSet.contains(phrase.id)) {
        count++;
      }
    }
    return count;
  }

  /// Optimistically toggles favorite status for [phraseSlug].
  ///
  /// Reverts and returns error on write failure. Ignores repeated calls while
  /// a write for the same phrase is in flight.
  Future<RepoResult<bool>> toggleFavorite(String phraseSlug) async {
    final uid = _currentUid;
    if (uid == null) {
      return const RepoResult.error('Please sign in to save favorites.');
    }

    if (_inFlightFavoriteOperations.contains(phraseSlug)) {
      // Ignore repeated taps while operation is in flight
      return RepoResult.success(isFavorite(phraseSlug));
    }

    _inFlightFavoriteOperations.add(phraseSlug);
    final wasFavorite = _favoriteSet.contains(phraseSlug);
    final newFavorite = !wasFavorite;

    // 1. Optimistic Update
    if (newFavorite) {
      _favoriteIds.insert(0, phraseSlug);
      _favoriteSet.add(phraseSlug);
    } else {
      _favoriteIds.remove(phraseSlug);
      _favoriteSet.remove(phraseSlug);
    }
    notifyListeners();

    // 2. Background Firestore write
    try {
      final result = newFavorite
          ? await _repository.addFavorite(uid, phraseSlug)
          : await _repository.removeFavorite(uid, phraseSlug);

      if (result.isError) {
        // Rollback
        if (newFavorite) {
          _favoriteIds.remove(phraseSlug);
          _favoriteSet.remove(phraseSlug);
        } else {
          _favoriteIds.insert(0, phraseSlug);
          _favoriteSet.add(phraseSlug);
        }
        notifyListeners();
        return RepoResult.error(result.errorMessageOrNull ?? 'Failed to update favorite.');
      }

      return RepoResult.success(newFavorite);
    } catch (e) {
      // Rollback on unexpected exception
      if (newFavorite) {
        _favoriteIds.remove(phraseSlug);
        _favoriteSet.remove(phraseSlug);
      } else {
        _favoriteIds.insert(0, phraseSlug);
        _favoriteSet.add(phraseSlug);
      }
      notifyListeners();
      return RepoResult.error('Failed to update favorite: $e');
    } finally {
      _inFlightFavoriteOperations.remove(phraseSlug);
    }
  }

  /// Optimistically toggles learned status for [phraseSlug] in [targetLanguageCode].
  ///
  /// Reverts and returns error on write failure. Ignores repeated calls while
  /// a write for the same phrase and language is in flight.
  Future<RepoResult<bool>> toggleLearned(
    String phraseSlug,
    String targetLanguageCode,
  ) async {
    final uid = _currentUid;
    if (uid == null) {
      return const RepoResult.error('Please sign in to track learned phrases.');
    }

    final opKey = '${phraseSlug}__$targetLanguageCode';
    if (_inFlightLearnedOperations.contains(opKey)) {
      return RepoResult.success(isLearned(phraseSlug, targetLanguageCode));
    }

    _inFlightLearnedOperations.add(opKey);
    final langSet = _learnedPhraseIdsByLanguage.putIfAbsent(targetLanguageCode, () => <String>{});
    final wasLearned = langSet.contains(phraseSlug);
    final newLearned = !wasLearned;

    // 1. Optimistic Update
    if (newLearned) {
      langSet.add(phraseSlug);
    } else {
      langSet.remove(phraseSlug);
    }
    notifyListeners();

    // 2. Background Firestore write
    try {
      final result = newLearned
          ? await _repository.markPhraseLearned(uid, phraseSlug, targetLanguageCode)
          : await _repository.unmarkPhraseLearned(uid, phraseSlug, targetLanguageCode);

      if (result.isError) {
        // Rollback
        if (newLearned) {
          langSet.remove(phraseSlug);
        } else {
          langSet.add(phraseSlug);
        }
        notifyListeners();
        return RepoResult.error(result.errorMessageOrNull ?? 'Failed to update learned state.');
      }

      return RepoResult.success(newLearned);
    } catch (e) {
      // Rollback
      if (newLearned) {
        langSet.remove(phraseSlug);
      } else {
        langSet.add(phraseSlug);
      }
      notifyListeners();
      return RepoResult.error('Failed to update learned state: $e');
    } finally {
      _inFlightLearnedOperations.remove(opKey);
    }
  }

  /// Records a study visit for [phraseSlug].
  ///
  /// Optimistically places [phraseSlug] at index 0 of the recent queue.
  /// Failure is silently ignored to never block or slow the study UI.
  void recordRecentView(String phraseSlug) {
    final uid = _currentUid;
    if (uid == null) return;

    // Optimistically update recent list
    _recentPhraseIds.remove(phraseSlug);
    _recentPhraseIds.insert(0, phraseSlug);
    if (_recentPhraseIds.length > 20) {
      _recentPhraseIds.removeRange(20, _recentPhraseIds.length);
    }
    notifyListeners();

    // Fire non-blocking background write
    _repository.recordRecentView(uid, phraseSlug).catchError((_) {
      return const RepoResult<void>.error('Failed to record recent view');
    });
  }

  @override
  void dispose() {
    authController?.removeListener(_onAuthChanged);
    super.dispose();
  }
}
