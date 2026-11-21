import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central state manager for user language settings, onboarding state,
/// appearance (theme mode), and reading preferences (text size & recall mode).
///
/// Defaults on first launch: English ('en') as native and Spanish ('es') as target.
/// Enforces that native and target languages are never the same; selecting the same
/// language swaps them automatically.
///
/// Appearance and reading preferences are stored locally only and are not synced
/// to the cloud.
class LanguageSettingsController extends ChangeNotifier {
  static const String keyNativeLanguage = 'pref_native_language';
  static const String keyTargetLanguage = 'pref_target_language';
  static const String keyHasOnboarded = 'pref_has_onboarded';
  static const String keyThemeMode = 'pref_theme_mode';
  static const String keyStudyTextSize = 'study_text_size_index';
  static const String keyStudyRecallMode = 'study_recall_mode';

  String _nativeLanguageCode = 'en';
  String _targetLanguageCode = 'es';
  bool _hasOnboarded = false;
  ThemeMode _themeMode = ThemeMode.system;
  int _studyTextSizeIndex = 0; // 0: Default, 1: Large, 2: Extra Large
  bool _studyRecallMode = false;
  bool _isLoaded = false;

  LanguageSettingsController({SharedPreferences? preferences}) {
    if (preferences != null) {
      _loadFromPreferences(preferences);
    }
  }

  String get nativeLanguageCode => _nativeLanguageCode;
  String get targetLanguageCode => _targetLanguageCode;
  bool get hasOnboarded => _hasOnboarded;
  ThemeMode get themeMode => _themeMode;
  int get studyTextSizeIndex => _studyTextSizeIndex;
  bool get studyRecallMode => _studyRecallMode;
  bool get isLoaded => _isLoaded;

  /// Loads persisted settings from SharedPreferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _loadFromPreferences(prefs);
  }

  void _loadFromPreferences(SharedPreferences prefs) {
    _nativeLanguageCode = prefs.getString(keyNativeLanguage) ?? 'en';
    _targetLanguageCode = prefs.getString(keyTargetLanguage) ?? 'es';
    _hasOnboarded = prefs.getBool(keyHasOnboarded) ?? false;
    _themeMode = _parseThemeMode(prefs.getString(keyThemeMode));
    final rawSize = prefs.getInt(keyStudyTextSize) ?? 0;
    _studyTextSizeIndex = rawSize.clamp(0, 2);
    _studyRecallMode = prefs.getBool(keyStudyRecallMode) ?? false;

    // Safety fallback: ensure they are never the same upon load
    if (_nativeLanguageCode == _targetLanguageCode) {
      if (_nativeLanguageCode == 'en') {
        _targetLanguageCode = 'es';
      } else {
        _targetLanguageCode = 'en';
      }
    }

    _isLoaded = true;
    notifyListeners();
  }

  static ThemeMode _parseThemeMode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _serializeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Sets the appearance theme mode locally.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyThemeMode, _serializeThemeMode(mode));
  }

  /// Sets the study text size index (0: Default, 1: Large, 2: Extra Large) locally.
  Future<void> setStudyTextSizeIndex(int index) async {
    final clamped = index.clamp(0, 2);
    if (clamped == _studyTextSizeIndex) return;
    _studyTextSizeIndex = clamped;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyStudyTextSize, clamped);
  }

  /// Cycles the study text size through Default -> Large -> Extra Large -> Default.
  Future<void> cycleStudyTextSize() async {
    await setStudyTextSizeIndex((_studyTextSizeIndex + 1) % 3);
  }

  /// Sets the study recall mode preference locally.
  Future<void> setStudyRecallMode(bool enabled) async {
    if (enabled == _studyRecallMode) return;
    _studyRecallMode = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyStudyRecallMode, enabled);
  }

  /// Sets the native language code. If set to the current target language, swaps them.
  Future<void> setNativeLanguage(String code) async {
    if (code.isEmpty || code == _nativeLanguageCode) return;

    if (code == _targetLanguageCode) {
      // Swap languages
      _targetLanguageCode = _nativeLanguageCode;
      _nativeLanguageCode = code;
    } else {
      _nativeLanguageCode = code;
    }

    notifyListeners();
    await _persist();
  }

  /// Sets the target language code. If set to the current native language, swaps them.
  Future<void> setTargetLanguage(String code) async {
    if (code.isEmpty || code == _targetLanguageCode) return;

    if (code == _nativeLanguageCode) {
      // Swap languages
      _nativeLanguageCode = _targetLanguageCode;
      _targetLanguageCode = code;
    } else {
      _targetLanguageCode = code;
    }

    notifyListeners();
    await _persist();
  }

  /// Sets both languages at once, ensuring they are not identical.
  Future<void> setLanguagePair({
    required String nativeCode,
    required String targetCode,
  }) async {
    if (nativeCode == targetCode) {
      // Swapping or defaulting if identical
      if (nativeCode == _nativeLanguageCode) {
        _targetLanguageCode = _nativeLanguageCode;
        _nativeLanguageCode = targetCode == 'en' ? 'es' : 'en';
      } else {
        _nativeLanguageCode = nativeCode;
        _targetLanguageCode = nativeCode == 'en' ? 'es' : 'en';
      }
    } else {
      _nativeLanguageCode = nativeCode;
      _targetLanguageCode = targetCode;
    }

    notifyListeners();
    await _persist();
  }

  /// Swaps the native and target language codes.
  Future<void> swapLanguages() async {
    final temp = _nativeLanguageCode;
    _nativeLanguageCode = _targetLanguageCode;
    _targetLanguageCode = temp;

    notifyListeners();
    await _persist();
  }

  /// Marks onboarding as completed and persists to SharedPreferences.
  Future<void> completeOnboarding() async {
    _hasOnboarded = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyHasOnboarded, true);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyNativeLanguage, _nativeLanguageCode);
    await prefs.setString(keyTargetLanguage, _targetLanguageCode);
  }
}
