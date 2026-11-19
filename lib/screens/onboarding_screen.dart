import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../models/language.dart';
import '../services/browse_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/language_chip.dart';
import '../widgets/language_picker_bottom_sheet.dart';

/// Onboarding screen allowing language selection before entering the app.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  List<Language> _availableLanguages = [];
  bool _isLoading = true;

  late Language _nativeLang;
  late Language _targetLang;

  @override
  void initState() {
    super.initState();
    _nativeLang = const Language(code: 'en', name: 'English', nativeName: 'English');
    _targetLang = const Language(code: 'es', name: 'Spanish', nativeName: 'Español');
    _loadRealLanguages();
  }

  Future<void> _loadRealLanguages() async {
    final result = await BrowseDataService.instance.getLanguages();
    if (mounted && result.isSuccess && result.dataOrNull != null) {
      final langs = result.dataOrNull!;
      setState(() {
        _availableLanguages = langs;
        _isLoading = false;

        // Initialize with default or current settings
        final settings = AppSettingsScope.maybeOf(context);
        final nativeCode = settings?.nativeLanguageCode ?? 'en';
        final targetCode = settings?.targetLanguageCode ?? 'es';

        _nativeLang = langs.firstWhere(
          (l) => l.code == nativeCode,
          orElse: () => langs.firstWhere((l) => l.code == 'en', orElse: () => langs.first),
        );
        _targetLang = langs.firstWhere(
          (l) => l.code == targetCode,
          orElse: () => langs.firstWhere((l) => l.code == 'es', orElse: () => langs.last),
        );

        if (_nativeLang.code == _targetLang.code) {
          _targetLang = langs.firstWhere((l) => l.code != _nativeLang.code, orElse: () => _targetLang);
        }
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectNativeLanguage() async {
    final selected = await LanguagePickerBottomSheet.show(
      context,
      selectedLanguage: _nativeLang,
      title: 'Select Your Native Language',
      availableLanguages: _availableLanguages,
    );
    if (selected != null && mounted) {
      if (selected.code == _targetLang.code) {
        // Automatically swap languages so they are never identical
        setState(() {
          _targetLang = _nativeLang;
          _nativeLang = selected;
        });
      } else {
        setState(() => _nativeLang = selected);
      }
    }
  }

  void _selectTargetLanguage() async {
    final selected = await LanguagePickerBottomSheet.show(
      context,
      selectedLanguage: _targetLang,
      title: 'Select Language to Practice',
      availableLanguages: _availableLanguages,
    );
    if (selected != null && mounted) {
      if (selected.code == _nativeLang.code) {
        // Automatically swap languages so they are never identical
        setState(() {
          _nativeLang = _targetLang;
          _targetLang = selected;
        });
      } else {
        setState(() => _targetLang = selected);
      }
    }
  }

  Future<void> _completeOnboarding() async {
    final settings = AppSettingsScope.of(context);
    await settings.setLanguagePair(
      nativeCode: _nativeLang.code,
      targetCode: _targetLang.code,
    );
    await settings.completeOnboarding();

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Practice'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: AppLoadingIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personalize Your Reading',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Phrase Practice emphasizes immersive sentence exposure and crystal-clear translations.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Native Language
                    Text(
                      'I speak (Native)',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    LanguageChip(
                      language: _nativeLang,
                      isSelected: true,
                      onTap: _selectNativeLanguage,
                      semanticsLabel: 'I speak ${_nativeLang.name}. Tap to change native language.',
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Target Language
                    Text(
                      'I want to study',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    LanguageChip(
                      language: _targetLang,
                      isSelected: true,
                      onTap: _selectTargetLanguage,
                      semanticsLabel: 'I want to study ${_targetLang.name}. Tap to change study language.',
                    ),

                    const Spacer(),

                    AppPrimaryButton(
                      label: 'Start Practicing',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _completeOnboarding,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
