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
///
/// Fully scrollable to prevent any RenderFlex overflow across all screen sizes
/// (320px to 1280px) and extreme text scale factors (up to 2.0x).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  List<Language> _availableLanguages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRealLanguages();
  }

  Future<void> _loadRealLanguages() async {
    final result = await BrowseDataService.instance.getLanguages();
    if (mounted && result.isSuccess && result.dataOrNull != null) {
      setState(() {
        _availableLanguages = result.dataOrNull!;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Language _findLang(String code, String fallbackCode) {
    return _availableLanguages.firstWhere(
      (l) => l.code == code,
      orElse: () => _availableLanguages.firstWhere(
        (l) => l.code == fallbackCode,
        orElse: () => Language(code: code, name: code, nativeName: code),
      ),
    );
  }

  void _selectNativeLanguage(Language currentNative) async {
    final selected = await LanguagePickerBottomSheet.show(
      context,
      selectedLanguage: currentNative,
      title: 'I speak (Native Language)',
      availableLanguages: _availableLanguages,
    );
    if (selected != null && mounted) {
      final settings = AppSettingsScope.of(context);
      await settings.setNativeLanguage(selected.code);
    }
  }

  void _selectTargetLanguage(Language currentTarget) async {
    final selected = await LanguagePickerBottomSheet.show(
      context,
      selectedLanguage: currentTarget,
      title: "I'm learning (Target Language)",
      availableLanguages: _availableLanguages,
    );
    if (selected != null && mounted) {
      final settings = AppSettingsScope.of(context);
      await settings.setTargetLanguage(selected.code);
    }
  }

  Future<void> _completeOnboarding() async {
    final settings = AppSettingsScope.of(context);
    await settings.completeOnboarding();
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = AppSettingsScope.of(context);

    final nativeLang = _findLang(settings.nativeLanguageCode, 'en');
    final targetLang = _findLang(settings.targetLanguageCode, 'es');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Practice'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: AppLoadingIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.lg,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - (AppSpacing.lg * 2),
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personalize Your Reading',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkText : AppColors.lightText,
                              ),
                              softWrap: true,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Phrase Practice emphasizes immersive sentence exposure and crystal-clear translations.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                height: 1.45,
                              ),
                              softWrap: true,
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Setting 1: "I speak"
                            Text(
                              'I speak',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkText : AppColors.lightText,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            LanguageChip(
                              language: nativeLang,
                              isSelected: true,
                              roleLabel: 'I speak',
                              onTap: () => _selectNativeLanguage(nativeLang),
                              semanticsLabel: 'I speak ${nativeLang.name}. Tap to change.',
                            ),

                            const SizedBox(height: AppSpacing.xl),

                            // Setting 2: "I'm learning"
                            Text(
                              "I'm learning",
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkText : AppColors.lightText,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            LanguageChip(
                              language: targetLang,
                              isSelected: true,
                              roleLabel: "I'm learning",
                              onTap: () => _selectTargetLanguage(targetLang),
                              semanticsLabel: "I'm learning ${targetLang.name}. Tap to change.",
                            ),

                            const Spacer(),
                            const SizedBox(height: AppSpacing.xl),

                            AppPrimaryButton(
                              label: 'Start Practicing',
                              icon: Icons.arrow_forward_rounded,
                              onPressed: _completeOnboarding,
                            ),
                            const SizedBox(height: AppSpacing.sm),

                            Center(
                              child: TextButton(
                                onPressed: () => context.push('/login'),
                                child: const Text('Already have an account? Sign in'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
