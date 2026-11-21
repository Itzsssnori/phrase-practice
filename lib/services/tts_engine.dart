import 'package:flutter/foundation.dart' show VoidCallback, kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'tts_voice_selector.dart';

/// Thin abstract interface over the `flutter_tts` plugin so tests can fake it
/// deterministically without invoking native channels or browser speech engines.
abstract class TtsEngine {
  /// Returns true when running on the web platform.
  bool get isWeb;

  /// Returns the voices reported by the platform, if supported.
  Future<List<TtsVoice>> getVoices();

  /// Returns the locale codes reported by the platform, if supported.
  Future<List<String>> getLanguages();

  /// Checks whether a specific locale code is available on the platform.
  Future<bool> isLanguageAvailable(String locale);

  /// Queries the platform's valid speech rate range, or `null` if unsupported (e.g. Web).
  Future<SpeechRateValidRange?> getSpeechRateValidRange();

  /// Sets the active speech language/locale on the engine.
  Future<void> setLanguage(String locale);

  /// Sets the active voice by name and locale on the engine.
  Future<void> setVoice(TtsVoice voice);

  /// Sets the speech rate on the engine.
  Future<void> setSpeechRate(double rate);

  /// Speaks [text] and returns the platform result (or throws on error).
  Future<dynamic> speak(String text);

  /// Stops any active speech playback immediately.
  Future<void> stop();

  /// Registers a callback invoked when speech playback begins.
  void setStartHandler(VoidCallback callback);

  /// Registers a callback invoked when speech playback finishes normally.
  void setCompletionHandler(VoidCallback callback);

  /// Registers a callback invoked when speech playback is cancelled.
  void setCancelHandler(VoidCallback callback);

  /// Registers a callback invoked when speech playback fails with an error.
  void setErrorHandler(void Function(dynamic message) handler);
}

/// Production [TtsEngine] implementation backed by [FlutterTts].
class FlutterTtsEngine implements TtsEngine {
  final FlutterTts _tts;

  FlutterTtsEngine({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  @override
  bool get isWeb => kIsWeb;

  @override
  Future<List<TtsVoice>> getVoices() async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return const [];
      final voices = <TtsVoice>[];
      for (final item in raw) {
        if (item is Map) {
          final name = item['name']?.toString().trim() ?? '';
          final locale = item['locale']?.toString().trim() ?? '';
          if (locale.isNotEmpty) {
            voices.add(TtsVoice(name: name, locale: locale));
          }
        }
      }
      return voices;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<String>> getLanguages() async {
    try {
      final raw = await _tts.getLanguages;
      if (raw is! List) return const [];
      return raw
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<bool> isLanguageAvailable(String locale) async {
    try {
      final res = await _tts.isLanguageAvailable(locale);
      return res == true || res == 1;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<SpeechRateValidRange?> getSpeechRateValidRange() async {
    if (kIsWeb) return null;
    try {
      return await _tts.getSpeechRateValidRange;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setLanguage(String locale) async {
    await _tts.setLanguage(locale);
  }

  @override
  Future<void> setVoice(TtsVoice voice) async {
    if (voice.name.isEmpty) return;
    await _tts.setVoice(voice.toMap());
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }

  @override
  Future<dynamic> speak(String text) async {
    return await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Ignore stop errors when engine is not initialized or already stopped.
    }
  }

  @override
  void setStartHandler(VoidCallback callback) {
    _tts.setStartHandler(callback);
  }

  @override
  void setCompletionHandler(VoidCallback callback) {
    _tts.setCompletionHandler(callback);
  }

  @override
  void setCancelHandler(VoidCallback callback) {
    _tts.setCancelHandler(callback);
  }

  @override
  void setErrorHandler(void Function(dynamic message) handler) {
    _tts.setErrorHandler(handler);
  }
}
