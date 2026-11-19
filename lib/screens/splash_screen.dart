import 'package:material_ui/material_ui.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_loading_indicator.dart';

/// Initial loading / splash screen shown while Firebase Auth and app dependencies load.
///
/// Route guards in [GoRouter] automatically transition to `/home` or `/onboarding`
/// as soon as the first authentication state resolves.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Minimal, approachable logo mark
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPrimaryContainer : AppColors.lightPrimaryContainer,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 38,
                  color: isDark ? AppColors.darkOnPrimaryContainer : AppColors.lightOnPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Phrase Practice',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Read, understand, and internalize phrases naturally in real context.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              const AppLoadingIndicator(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
