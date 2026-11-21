import 'package:flutter/foundation.dart';
import '../models/quiz_attempt.dart';
import 'auth_controller.dart';
import 'progress_calculator.dart';
import 'quiz_attempt_repository.dart';
import 'quiz_controller.dart';

/// Session-scoped state manager for the signed-in user's recent quiz attempts
/// used on the Progress screen.
///
/// Loads at most [attemptLimit] (20) recent attempts once per session on demand,
/// and invalidates/reloads automatically whenever a new quiz attempt is saved.
class ProgressController extends ChangeNotifier {
  static const int attemptLimit = ProgressCalculator.defaultAttemptWindowLimit;

  final QuizAttemptRepository _repository;
  final AuthController? authController;
  final QuizController? quizController;

  String? _loadedUid;
  bool _hasLoaded = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<QuizAttempt> _attempts = const [];
  int _lastObservedQuizVersion = 0;

  ProgressController({
    QuizAttemptRepository? repository,
    this.authController,
    this.quizController,
  }) : _repository = repository ?? FirestoreQuizAttemptRepository() {
    authController?.addListener(_onAuthChanged);
    if (quizController != null) {
      _lastObservedQuizVersion = quizController!.savedAttemptVersion;
      quizController!.addListener(_onQuizChanged);
    }
  }

  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  List<QuizAttempt> get attempts => List.unmodifiable(_attempts);

  QuizStatsSummary get quizStats => ProgressCalculator.computeQuizStats(
        _attempts,
        maxDisplay: ProgressCalculator.defaultDisplayAttemptLimit,
        windowLimit: attemptLimit,
      );

  void _onAuthChanged() {
    final uid = (authController != null && authController!.isSignedIn)
        ? authController!.user?.uid
        : null;
    if (uid == null) {
      if (_loadedUid != null || _attempts.isNotEmpty || _hasLoaded || _errorMessage != null) {
        clear();
      }
    } else if (_loadedUid != null && _loadedUid != uid) {
      clear();
    }
  }

  void _onQuizChanged() {
    final qc = quizController;
    if (qc == null) return;
    if (qc.savedAttemptVersion != _lastObservedQuizVersion) {
      _lastObservedQuizVersion = qc.savedAttemptVersion;
      // Invalidate cache; if already loaded for a signed-in user, reload immediately.
      final uid = (authController != null && authController!.isSignedIn)
          ? authController!.user?.uid
          : _loadedUid;
      _hasLoaded = false;
      if (uid != null && uid.isNotEmpty) {
        loadForUser(uid, force: true);
      } else {
        notifyListeners();
      }
    }
  }

  /// Ensures quiz attempts are loaded once per session for [uid].
  Future<void> ensureLoaded(String uid) async {
    if (_hasLoaded && _loadedUid == uid && _errorMessage == null) return;
    if (_isLoading && _loadedUid == uid) return;
    await loadForUser(uid, force: true);
  }

  /// Loads up to [attemptLimit] recent quiz attempts for [uid].
  Future<void> loadForUser(String uid, {bool force = false}) async {
    if (!force && _hasLoaded && _loadedUid == uid && _errorMessage == null) return;

    _loadedUid = uid;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _repository.getRecentAttempts(uid, limit: attemptLimit);
    if (_loadedUid != uid) return; // User signed out or switched while in flight

    _isLoading = false;
    if (res.isSuccess) {
      _attempts = res.dataOrNull ?? const [];
      _hasLoaded = true;
      _errorMessage = null;
    } else {
      _errorMessage = res.errorMessageOrNull ?? 'Could not load quiz history.';
    }
    notifyListeners();
  }

  /// Clears all cached quiz attempts (e.g. on sign-out or account deletion).
  void clear() {
    _loadedUid = null;
    _hasLoaded = false;
    _isLoading = false;
    _errorMessage = null;
    _attempts = const [];
    notifyListeners();
  }

  @override
  void dispose() {
    authController?.removeListener(_onAuthChanged);
    quizController?.removeListener(_onQuizChanged);
    super.dispose();
  }
}
