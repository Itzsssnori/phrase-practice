import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart' show SpeechRateValidRange;
import '../models/language.dart';
import 'language_settings_controller.dart';
import 'tts_engine.dart';
import 'tts_voice_selector.dart';

/// Availability status of a TTS voice for a specific language code on this device.
enum VoiceAvailability {
  checking,
  available,
  unavailable,
}

/// ChangeNotifier managing Text-to-Speech voice availability, selection,
/// speech rate mapping, and single-utterance playback lifecycle.
class SpeechService extends ChangeNotifier with WidgetsBindingObserver {
  final TtsEngine _engine;
  final LanguageSettingsController? settingsController;
  final Duration maxVoiceLoadWait;
  final Duration voicePollInterval;
  final Duration startTimeoutDuration;

  final Map<String, VoiceAvailability> _availabilityByLang = {};
  final Map<String, TtsVoiceMatch> _voiceMatchByLang = {};
  final Map<String, Future<VoiceAvailability>> _inFlightChecks = {};

  SpeechRateValidRange? _cachedRateRange;
  bool _rateRangeChecked = false;

  String? _activeUtteranceId;
  String? _activeText;
  String? _activeLanguageCode;
  bool _isPlaying = false;
  bool _hasStartedCurrentUtterance = false;
  bool _isStoppingIntentionally = false;
  int _playbackSessionId = 0;
  Timer? _startTimeoutTimer;
  String? _lastErrorUtteranceId;
  VoidCallback? _activeOnErrorCallback;

  String? _lastNativeLang;
  String? _lastTargetLang;
  bool _observerAttached = false;
  bool _isDisposed = false;

  SpeechService({
    TtsEngine? engine,
    this.settingsController,
    this.maxVoiceLoadWait = const Duration(seconds: 3),
    this.voicePollInterval = const Duration(milliseconds: 250),
    this.startTimeoutDuration = const Duration(seconds: 10),
  }) : _engine = engine ?? FlutterTtsEngine() {
    _bindEngineHandlers();
    _attachSettingsListener();
    _attachLifecycleObserver();
  }

  TtsEngine get engine => _engine;
  bool get isPlaying => _isPlaying;
  String? get activeUtteranceId => _activeUtteranceId;
  String? get activeText => _activeText;
  String? get activeLanguageCode => _activeLanguageCode;
  String? get lastErrorUtteranceId => _lastErrorUtteranceId;

  /// Returns true if [utteranceId] is currently playing.
  bool isPlayingUtterance(String utteranceId) =>
      _isPlaying && _activeUtteranceId == utteranceId;

  /// Returns true if the most recent playback failure occurred on [utteranceId].
  bool hasErrorForUtterance(String utteranceId) =>
      _lastErrorUtteranceId == utteranceId;

  /// Returns the current availability state for [languageCode].
  /// Defaults to [VoiceAvailability.checking] before the first check completes.
  VoiceAvailability availabilityFor(String languageCode) {
    final code = languageCode.trim().toLowerCase();
    return _availabilityByLang[code] ?? VoiceAvailability.checking;
  }

  /// Returns the cached [TtsVoiceMatch] for [languageCode], if available.
  TtsVoiceMatch? voiceMatchFor(String languageCode) {
    final code = languageCode.trim().toLowerCase();
    return _voiceMatchByLang[code];
  }

  void _bindEngineHandlers() {
    _engine.setStartHandler(_handleEngineStart);
    _engine.setCompletionHandler(_handleEngineComplete);
    _engine.setCancelHandler(_handleEngineCancel);
    _engine.setErrorHandler(_handleEngineError);
  }

  void _attachSettingsListener() {
    final settings = settingsController;
    if (settings == null) return;
    _lastNativeLang = settings.nativeLanguageCode;
    _lastTargetLang = settings.targetLanguageCode;
    settings.addListener(_onSettingsChanged);
  }

  void _attachLifecycleObserver() {
    try {
      WidgetsBinding.instance.addObserver(this);
      _observerAttached = true;
    } catch (_) {
      _observerAttached = false;
    }
  }

  void _onSettingsChanged() {
    final settings = settingsController;
    if (settings == null) return;
    final nativeChanged = settings.nativeLanguageCode != _lastNativeLang;
    final targetChanged = settings.targetLanguageCode != _lastTargetLang;
    _lastNativeLang = settings.nativeLanguageCode;
    _lastTargetLang = settings.targetLanguageCode;

    if ((nativeChanged || targetChanged) && _isPlaying) {
      unawaited(stop());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      if (_isPlaying) {
        unawaited(stop());
      }
    }
  }

  void _handleEngineStart() {
    if (!_isPlaying) return;
    _hasStartedCurrentUtterance = true;
    _startTimeoutTimer?.cancel();
    _startTimeoutTimer = null;
    notifyListeners();
  }

  void _handleEngineComplete() {
    if (!_isPlaying) return;
    _clearPlaybackState();
    notifyListeners();
  }

  void _handleEngineCancel() {
    if (!_isPlaying) return;
    _clearPlaybackState();
    notifyListeners();
  }

  void _handleEngineError(dynamic message) {
    if (_isStoppingIntentionally || !_isPlaying) return;
    final msgStr = message?.toString().toLowerCase() ?? '';
    if (msgStr.contains('canceled') ||
        msgStr.contains('cancelled') ||
        msgStr.contains('interrupted')) {
      _clearPlaybackState();
      notifyListeners();
      return;
    }
    _failCurrentPlayback();
  }

  void _failCurrentPlayback() {
    final failedUtteranceId = _activeUtteranceId;
    final errorCallback = _activeOnErrorCallback;
    _clearPlaybackState();
    _lastErrorUtteranceId = failedUtteranceId;
    notifyListeners();
    try {
      unawaited(_engine.stop());
    } catch (_) {}
    errorCallback?.call();
  }

  void _clearPlaybackState() {
    _startTimeoutTimer?.cancel();
    _startTimeoutTimer = null;
    _isPlaying = false;
    _hasStartedCurrentUtterance = false;
    _activeUtteranceId = null;
    _activeText = null;
    _activeLanguageCode = null;
    _activeOnErrorCallback = null;
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  /// Lazily checks availability for [languageCode] when a screen opens.
  ///
  /// If [languageCode] has never been checked, or was previously resolved as
  /// [VoiceAvailability.unavailable] and [recheckIfUnavailable] is true,
  /// triggers an asynchronous availability check.
  Future<VoiceAvailability> ensureLanguageChecked(
    String languageCode, {
    String? ttsLocale,
    bool recheckIfUnavailable = true,
  }) {
    if (_isDisposed) return Future.value(VoiceAvailability.unavailable);
    final code = languageCode.trim().toLowerCase();
    final current = _availabilityByLang[code];
    if (current == VoiceAvailability.available) {
      return Future.value(VoiceAvailability.available);
    }
    if (current == VoiceAvailability.unavailable && !recheckIfUnavailable) {
      return Future.value(VoiceAvailability.unavailable);
    }
    return checkAvailability(
      code,
      ttsLocale: ttsLocale,
      forceRefresh: current == VoiceAvailability.unavailable,
    );
  }

  /// Resolves and caches voice availability for [languageCode].
  ///
  /// On the web (or when voices load late), retries for up to [_maxVoiceLoadWait]
  /// (default 3 seconds) before concluding that no voice exists.
  Future<VoiceAvailability> checkAvailability(
    String languageCode, {
    String? ttsLocale,
    bool forceRefresh = false,
  }) async {
    final code = languageCode.trim().toLowerCase();
    if (code.isEmpty) return VoiceAvailability.unavailable;

    if (!forceRefresh && _availabilityByLang[code] == VoiceAvailability.available) {
      return VoiceAvailability.available;
    }

    final existingCheck = _inFlightChecks[code];
    if (existingCheck != null && !forceRefresh) {
      return existingCheck;
    }

    final prevState = _availabilityByLang[code];
    _availabilityByLang[code] = VoiceAvailability.checking;
    if (prevState != VoiceAvailability.checking) {
      notifyListeners();
    }

    final future = _performAvailabilityCheck(code, ttsLocale: ttsLocale);
    _inFlightChecks[code] = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlightChecks[code], future)) {
        _inFlightChecks.remove(code);
      }
    }
  }

  Future<VoiceAvailability> _performAvailabilityCheck(
    String code, {
    String? ttsLocale,
  }) async {
    final effectiveTtsLocale =
        (ttsLocale != null && ttsLocale.trim().isNotEmpty)
            ? ttsLocale.trim()
            : Language.defaultTtsLocaleFor(code);
    final preferences = TtsVoiceSelector.preferredLocalesFor(
      code,
      ttsLocale: effectiveTtsLocale,
    );

    final stopwatch = Stopwatch()..start();
    while (true) {
      final match = await _tryFindVoiceMatch(code, preferences);
      if (match != null) {
        _voiceMatchByLang[code] = match;
        _availabilityByLang[code] = VoiceAvailability.available;
        notifyListeners();
        return VoiceAvailability.available;
      }

      // On web (or when platform voice list is still empty and retry time remains),
      // retry up to maxVoiceLoadWait (3 seconds).
      final shouldRetry = _engine.isWeb &&
          stopwatch.elapsed + voicePollInterval <= maxVoiceLoadWait;
      if (!shouldRetry) {
        break;
      }
      await Future<void>.delayed(voicePollInterval);
    }

    _voiceMatchByLang.remove(code);
    _availabilityByLang[code] = VoiceAvailability.unavailable;
    notifyListeners();
    return VoiceAvailability.unavailable;
  }

  Future<TtsVoiceMatch?> _tryFindVoiceMatch(
    String code,
    List<String> preferences,
  ) async {
    List<TtsVoice> voices = const [];
    List<String> locales = const [];

    try {
      voices = await _engine.getVoices();
    } catch (_) {
      voices = const [];
    }

    try {
      locales = await _engine.getLanguages();
    } catch (_) {
      locales = const [];
    }

    final match = TtsVoiceSelector.selectVoice(
      languageCode: code,
      voices: voices,
      availableLocales: locales,
      preferredLocales: preferences,
    );
    if (match != null) return match;

    // Fallback: if neither getVoices nor getLanguages returned entries, probe
    // concrete preferred locale tags via isLanguageAvailable.
    if (voices.isEmpty && locales.isEmpty) {
      for (final pattern in preferences) {
        if (pattern.endsWith('-*')) continue;
        try {
          final available = await _engine.isLanguageAvailable(pattern);
          if (available) {
            return TtsVoiceMatch(voice: null, locale: pattern);
          }
        } catch (_) {}
      }
    }

    return null;
  }

  /// Clears cached availability and re-checks every language code in [languageCodes].
  Future<void> recheckLanguages(Iterable<String> languageCodes) async {
    final codes = languageCodes
        .map((c) => c.trim().toLowerCase())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    for (final code in codes) {
      _availabilityByLang[code] = VoiceAvailability.checking;
      _voiceMatchByLang.remove(code);
      _inFlightChecks.remove(code);
    }
    notifyListeners();

    await Future.wait(
      codes.map((code) => checkAvailability(code, forceRefresh: true)),
    );
  }

  /// Speaks [text] in [languageCode] for the button identified by [utteranceId].
  ///
  /// - If [utteranceId] is already playing, stops playback and returns `true`.
  /// - If another utterance is playing, stops it before starting the new one.
  /// - Never throws into the UI; on any error or 10-second start timeout, resets
  ///   to idle and invokes [onError].
  Future<bool> speak({
    required String text,
    required String languageCode,
    required String utteranceId,
    VoidCallback? onError,
  }) async {
    final trimmedText = text.trim();
    final code = languageCode.trim().toLowerCase();
    if (trimmedText.isEmpty || code.isEmpty) return false;

    // Tapping the currently active button stops playback.
    if (_isPlaying && _activeUtteranceId == utteranceId) {
      await stop();
      return true;
    }

    // Only one playback at a time: stop any current playback first.
    if (_isPlaying) {
      await stop();
    }

    _lastErrorUtteranceId = null;

    // Ensure voice availability is resolved.
    var availability = _availabilityByLang[code];
    if (availability == null || availability == VoiceAvailability.checking) {
      availability = await checkAvailability(code);
    }
    if (availability != VoiceAvailability.available) {
      return false;
    }

    final match = _voiceMatchByLang[code];
    if (match == null) {
      return false;
    }

    final sessionId = ++_playbackSessionId;
    _activeUtteranceId = utteranceId;
    _activeText = trimmedText;
    _activeLanguageCode = code;
    _activeOnErrorCallback = onError;
    _isPlaying = true;
    _hasStartedCurrentUtterance = false;
    _isStoppingIntentionally = false;
    notifyListeners();

    // Start 10-second timeout timer in case the engine never fires onStart.
    _startTimeoutTimer?.cancel();
    _startTimeoutTimer = Timer(startTimeoutDuration, () {
      if (_isPlaying &&
          _playbackSessionId == sessionId &&
          !_hasStartedCurrentUtterance) {
        _failCurrentPlayback();
      }
    });

    try {
      await _engine.setLanguage(match.locale);
      if (match.voice != null && match.voice!.name.isNotEmpty) {
        await _engine.setVoice(match.voice!);
      }

      if (!_rateRangeChecked && !_engine.isWeb) {
        _rateRangeChecked = true;
        try {
          _cachedRateRange = await _engine.getSpeechRateValidRange();
        } catch (_) {
          _cachedRateRange = null;
        }
      }

      final speed = settingsController?.speechSpeed ?? SpeechSpeed.normal;
      final rate = TtsVoiceSelector.mapSpeechRate(
        speed: speed,
        validRange: _cachedRateRange,
        isWeb: _engine.isWeb,
      );
      await _engine.setSpeechRate(rate);

      // Verify this playback session wasn't cancelled while awaiting engine config.
      if (!_isPlaying || _playbackSessionId != sessionId) {
        return false;
      }

      final result = await _engine.speak(trimmedText);
      if (!_isPlaying || _playbackSessionId != sessionId) {
        return true;
      }
      if (result == 0 || result == false) {
        _failCurrentPlayback();
        return false;
      }
      return true;
    } catch (_) {
      if (_playbackSessionId == sessionId && _isPlaying) {
        _failCurrentPlayback();
      }
      return false;
    }
  }

  /// Stops active playback only if [utteranceId] is the currently playing utterance.
  Future<void> stopIfPlayingUtterance(String utteranceId) async {
    if (_isPlaying && _activeUtteranceId == utteranceId) {
      await stop();
    }
  }

  /// Immediately stops any active speech playback.
  Future<void> stop() async {
    if (_isDisposed) {
      _clearPlaybackState();
      return;
    }
    final wasPlaying = _isPlaying;
    _isStoppingIntentionally = true;
    _playbackSessionId++;
    _clearPlaybackState();
    if (wasPlaying) {
      notifyListeners();
    }
    try {
      await _engine.stop();
    } catch (_) {
      // Never throw into the UI.
    } finally {
      _isStoppingIntentionally = false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _clearPlaybackState();
    _startTimeoutTimer?.cancel();
    settingsController?.removeListener(_onSettingsChanged);
    if (_observerAttached) {
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (_) {}
    }
    try {
      unawaited(_engine.stop());
    } catch (_) {}
    super.dispose();
  }
}
