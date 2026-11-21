import 'package:flutter/foundation.dart';
import '../models/language.dart';
import '../models/result.dart';
import '../models/translation_entry.dart';
import 'app_check_service.dart';
import 'auth_controller.dart';
import 'translation_history_repository.dart';
import 'translator_repository.dart';

/// Holds a pending optimistic deletion so the user can Undo before committing to Firestore.
class _PendingHistoryDelete {
  final TranslationHistoryItem item;
  final int index;

  const _PendingHistoryDelete({
    required this.item,
    required this.index,
  });
}

/// Central state manager for the AI Translator and the user's private translation history.
class TranslatorController extends ChangeNotifier {
  static const Duration minRequestGap = Duration(seconds: 3);
  static const Duration quotaCooldown = Duration(seconds: 60);
  static const int historyLoadLimit = 50;

  final TranslatorRepository _translatorRepo;
  final TranslationHistoryRepository _historyRepo;
  final AuthController? authController;
  final DateTime Function() _now;
  final bool Function()? _isAvailableOverride;

  String? _loadedUid;
  bool _hasLoadedHistory = false;
  bool _isLoadingHistory = false;
  String? _historyError;
  final List<TranslationHistoryItem> _history = [];
  final Map<String, _PendingHistoryDelete> _pendingDeletes = {};
  final Set<String> _inFlightSavedToggles = {};

  bool _isTranslating = false;
  TranslationResult? _currentResult;
  String? _errorMessage;
  String? _errorCode;
  bool _isSavingHistory = false;
  bool _saveFailed = false;
  DateTime? _cooldownUntil;

  TranslatorController({
    TranslatorRepository? translatorRepository,
    TranslationHistoryRepository? historyRepository,
    this.authController,
    DateTime Function()? clock,
    bool Function()? isAvailableOverride,
  })  : _translatorRepo = translatorRepository ?? FirebaseAiTranslatorRepository(),
        _historyRepo = historyRepository ?? FirestoreTranslationHistoryRepository(),
        _now = clock ?? DateTime.now,
        // ignore: prefer_initializing_formals
        _isAvailableOverride = isAvailableOverride {
    authController?.addListener(_onAuthChanged);
  }

  // ─── Getters ──────────────────────────────────────────────────────────

  bool get isAvailable =>
      _isAvailableOverride?.call() ?? AppCheckService.isTranslatorAvailable;

  bool get isTranslating => _isTranslating;
  TranslationResult? get currentResult => _currentResult;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;
  bool get isSavingHistory => _isSavingHistory;
  bool get saveFailed => _saveFailed;

  bool get isLoadingHistory => _isLoadingHistory;
  bool get hasLoadedHistory => _hasLoadedHistory;
  String? get historyError => _historyError;
  List<TranslationHistoryItem> get history => List.unmodifiable(_history);
  List<TranslationHistoryItem> get savedHistory =>
      List.unmodifiable(_history.where((e) => e.isSaved));

  Duration get cooldownRemaining {
    final until = _cooldownUntil;
    if (until == null) return Duration.zero;
    final diff = until.difference(_now());
    return diff.isNegative ? Duration.zero : diff;
  }

  int get cooldownRemainingSeconds {
    final rem = cooldownRemaining;
    if (rem == Duration.zero) return 0;
    return rem.inSeconds + (rem.inMilliseconds % 1000 > 0 ? 1 : 0);
  }

  bool get isCoolingDown => cooldownRemaining > Duration.zero;

  bool get canTranslate =>
      isAvailable &&
      !_isTranslating &&
      !isCoolingDown &&
      (authController?.isSignedIn ?? false) &&
      (authController?.isEmailVerified ?? false);

  void _onAuthChanged() {
    final uid = (authController != null && authController!.isSignedIn)
        ? authController!.user?.uid
        : null;
    if (uid == null) {
      if (_loadedUid != null ||
          _history.isNotEmpty ||
          _currentResult != null ||
          _errorMessage != null) {
        clear();
      }
    } else if (_loadedUid != null && _loadedUid != uid) {
      clear();
    }
  }

  // ─── History Loading ──────────────────────────────────────────────────

  /// Loads up to 50 recent translations once per session for [uid].
  Future<void> ensureHistoryLoaded(String uid) async {
    if (_hasLoadedHistory && _loadedUid == uid && _historyError == null) return;
    if (_isLoadingHistory && _loadedUid == uid) return;
    await loadHistory(uid, force: true);
  }

  Future<void> loadHistory(String uid, {bool force = false}) async {
    if (!force && _hasLoadedHistory && _loadedUid == uid && _historyError == null) {
      return;
    }

    _loadedUid = uid;
    _isLoadingHistory = true;
    _historyError = null;
    notifyListeners();

    final res = await _historyRepo.getRecentHistory(uid, limit: historyLoadLimit);
    if (_loadedUid != uid) return;

    _isLoadingHistory = false;
    if (res.isSuccess) {
      _history
        ..clear()
        ..addAll(res.dataOrNull ?? const []);
      _hasLoadedHistory = true;
      _historyError = null;
    } else {
      _historyError =
          res.errorMessageOrNull ?? 'Could not load translation history.';
    }
    notifyListeners();
  }

  // ─── Translation Execution ────────────────────────────────────────────

  /// Looks up a matching entry in the signed-in user's loaded history
  /// (same normalized case-insensitive input + same language pair).
  TranslationHistoryItem? findInLoadedHistory({
    required String normalizedInput,
    required String sourceLanguageCode,
    required String targetLanguageCode,
  }) {
    final targetLower = normalizedInput.toLowerCase();
    for (final item in _history) {
      if (item.sourceLanguageCode == sourceLanguageCode &&
          item.targetLanguageCode == targetLanguageCode &&
          TranslatorInputValidator.normalize(item.inputText).toLowerCase() ==
              targetLower) {
        return item;
      }
    }
    return null;
  }

  /// Translates [rawInput] from [sourceLanguage] to [targetLanguage].
  ///
  /// Enforces access gates (signed in + verified email + App Check available),
  /// input validation, cooldown/rate-limit, and history-first lookup before
  /// calling Gemini.
  Future<RepoResult<TranslationResult>> translate({
    required String rawInput,
    required Language sourceLanguage,
    required Language targetLanguage,
  }) async {
    // 1. Access & availability gates — never call Gemini if gated
    if (!isAvailable) {
      _errorMessage = 'Translator is unavailable right now.';
      _errorCode = TranslatorErrorMapper.unavailableErrorCode;
      notifyListeners();
      return RepoResult.error(_errorMessage!, _errorCode);
    }

    final auth = authController;
    if (auth == null || !auth.isSignedIn || auth.user == null) {
      return const RepoResult.error(
        'Please sign in to use the translator.',
        'auth-required',
      );
    }

    if (!auth.isEmailVerified) {
      return const RepoResult.error(
        'Please verify your email to use the translator.',
        'email-unverified',
      );
    }

    // 2. Prevent concurrent or rapid-fire requests
    if (_isTranslating) {
      return const RepoResult.error(
        'A translation is already in progress.',
        'in-flight',
      );
    }

    if (isCoolingDown) {
      return RepoResult.error(
        'Please wait ${cooldownRemainingSeconds}s before translating again.',
        TranslatorErrorMapper.quotaErrorCode,
      );
    }

    // 3. Validate & normalize input
    final validationError = TranslatorInputValidator.validate(rawInput);
    if (validationError != null) {
      return RepoResult.error(validationError, 'invalid-input');
    }

    final normalized = TranslatorInputValidator.normalize(rawInput);
    final uid = auth.user!.uid;

    // 4. History-first lookup: avoid calling Gemini if already in loaded history
    final existing = findInLoadedHistory(
      normalizedInput: normalized,
      sourceLanguageCode: sourceLanguage.code,
      targetLanguageCode: targetLanguage.code,
    );
    if (existing != null) {
      final result = existing.toTranslationResult(
        sourceLanguageName: sourceLanguage.name,
        targetLanguageName: targetLanguage.name,
        fromHistory: true,
      );
      _currentResult = result;
      _errorMessage = null;
      _errorCode = null;
      _saveFailed = false;
      notifyListeners();
      return RepoResult.success(result);
    }

    // 5. Call Gemini through TranslatorRepository
    _isTranslating = true;
    _errorMessage = null;
    _errorCode = null;
    _saveFailed = false;
    notifyListeners();

    final res = await _translatorRepo.translate(
      inputText: normalized,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );

    _isTranslating = false;

    if (res is ErrorResult<TranslationResult>) {
      final code = res.error is String ? res.error as String : null;
      _errorMessage = res.message;
      _errorCode = code;
      // Start visible cooldown: 60s for quota/429, 3s minimum gap otherwise
      _cooldownUntil = _now().add(
        code == TranslatorErrorMapper.quotaErrorCode
            ? quotaCooldown
            : minRequestGap,
      );
      notifyListeners();
      return res;
    }

    final result = res.dataOrNull!;
    _currentResult = result;
    _errorMessage = null;
    _errorCode = null;
    _cooldownUntil = _now().add(minRequestGap);
    notifyListeners();

    // 6. Save to signed-in user's history only when status == ok
    if (result.isOk) {
      await _saveResultToHistory(uid, result);
    }

    return RepoResult.success(result);
  }

  Future<void> _saveResultToHistory(String uid, TranslationResult result) async {
    _isSavingHistory = true;
    _saveFailed = false;
    notifyListeners();

    final saveRes = await _historyRepo.saveTranslation(uid, result);
    _isSavingHistory = false;

    if (saveRes.isSuccess && saveRes.dataOrNull != null) {
      _history.insert(0, saveRes.dataOrNull!);
      if (_history.length > historyLoadLimit) {
        _history.removeRange(historyLoadLimit, _history.length);
      }
      _saveFailed = false;
    } else {
      // Keep showing the result; show quiet retry message
      _saveFailed = true;
    }
    notifyListeners();
  }

  /// Retries saving the currently displayed result to history.
  Future<void> retrySaveCurrentResult() async {
    final uid = authController?.user?.uid;
    final result = _currentResult;
    if (uid == null || result == null || !result.isOk || _isSavingHistory) {
      return;
    }
    await _saveResultToHistory(uid, result);
  }

  /// Clears the currently displayed result/error (e.g. when tapping Clear).
  void clearCurrentResult() {
    _currentResult = null;
    _errorMessage = null;
    _errorCode = null;
    _saveFailed = false;
    notifyListeners();
  }

  // ─── History Mutations ────────────────────────────────────────────────

  /// Optimistically toggles `isSaved` for a history item, rolling back on failure.
  Future<RepoResult<bool>> toggleSaved(String id) async {
    final uid = authController?.user?.uid;
    if (uid == null) {
      return const RepoResult.error('Please sign in to save translations.');
    }
    if (_inFlightSavedToggles.contains(id)) {
      final existing = _history.where((e) => e.id == id).firstOrNull;
      return RepoResult.success(existing?.isSaved ?? false);
    }

    final idx = _history.indexWhere((e) => e.id == id);
    if (idx == -1) {
      return const RepoResult.error('Translation not found.');
    }

    _inFlightSavedToggles.add(id);
    final original = _history[idx];
    final nextSaved = !original.isSaved;

    // Optimistic update
    _history[idx] = original.copyWith(isSaved: nextSaved);
    notifyListeners();

    try {
      final res = await _historyRepo.setSaved(uid, id, nextSaved);
      if (res.isError) {
        final rollbackIdx = _history.indexWhere((e) => e.id == id);
        if (rollbackIdx != -1) {
          _history[rollbackIdx] = original;
          notifyListeners();
        }
        return RepoResult.error(
          res.errorMessageOrNull ?? 'Could not update saved status.',
        );
      }
      return RepoResult.success(nextSaved);
    } finally {
      _inFlightSavedToggles.remove(id);
    }
  }

  /// Removes a history item optimistically so the UI can show an Undo snackbar.
  TranslationHistoryItem? removeHistoryItemOptimistically(String id) {
    final idx = _history.indexWhere((e) => e.id == id);
    if (idx == -1) return null;
    final removed = _history.removeAt(idx);
    _pendingDeletes[id] = _PendingHistoryDelete(item: removed, index: idx);
    notifyListeners();
    return removed;
  }

  /// Restores an optimistically removed item when the user taps Undo.
  void undoRemoveHistoryItem(String id) {
    final pending = _pendingDeletes.remove(id);
    if (pending == null) return;
    final insertAt = pending.index.clamp(0, _history.length);
    _history.insert(insertAt, pending.item);
    notifyListeners();
  }

  /// Commits a pending optimistic deletion to Firestore (called when Undo window closes).
  Future<RepoResult<void>> commitRemoveHistoryItem(String id) async {
    final pending = _pendingDeletes.remove(id);
    if (pending == null) return const RepoResult.success(null);

    final uid = authController?.user?.uid;
    if (uid == null) return const RepoResult.success(null);

    final res = await _historyRepo.deleteOne(uid, id);
    if (res.isError) {
      // Roll back if Firestore delete failed
      final insertAt = pending.index.clamp(0, _history.length);
      _history.insert(insertAt, pending.item);
      notifyListeners();
    }
    return res;
  }

  /// Deletes all translation history for the signed-in user.
  Future<RepoResult<void>> clearHistory() async {
    final uid = authController?.user?.uid;
    if (uid == null) {
      return const RepoResult.error('Please sign in to manage history.');
    }

    _pendingDeletes.clear();
    final res = await _historyRepo.deleteAll(uid);
    if (res.isSuccess) {
      _history.clear();
      notifyListeners();
    }
    return res;
  }

  /// Clears all per-user state in memory (sign-out or account deletion).
  void clear() {
    _loadedUid = null;
    _hasLoadedHistory = false;
    _isLoadingHistory = false;
    _historyError = null;
    _history.clear();
    _pendingDeletes.clear();
    _inFlightSavedToggles.clear();
    _isTranslating = false;
    _currentResult = null;
    _errorMessage = null;
    _errorCode = null;
    _isSavingHistory = false;
    _saveFailed = false;
    _cooldownUntil = null;
    notifyListeners();
  }

  @override
  void dispose() {
    authController?.removeListener(_onAuthChanged);
    super.dispose();
  }
}
