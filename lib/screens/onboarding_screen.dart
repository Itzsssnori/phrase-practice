import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../models/language.dart';
import '../services/mock_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/language_chip.dart';
import '../widgets/language_picker_bottom_sheet.dart';

/// Onboarding screen allowing language selection before entering the app.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Language _nativeLang = MockDataService.sampleLanguages[0]; // English
  Language _targetLang = MockDataService.sampleLanguages[1]; // Spanish

  void _selectNativeLanguage() async {
    final selected = await LanguagePickerBottomSheet.show(
      context,
      selectedLanguage: _nativeLang,
      title: 'Select Your Native Language',
    );
    if (selected != null && mounted) {
      setState(() => _nativeLang = selected);
    }
  }

  void _selectTargetLanguage() async {
    final selected = await LanguagePickerBottomSheet.show(
      context,
      selectedLanguage: _targetLang,
      title: 'Select Language to Practice',
    );
    if (selected != null && mounted) {
      setState(() => _targetLang = selected);
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
        child: Padding(
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
              ),

              const Spacer(),

              AppPrimaryButton(
                label: 'Start Practicing',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
