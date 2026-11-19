import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_settings_scope.dart';

/// Initial loading / splash screen with onboarding check.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluateDestination();
    });
  }

  void _evaluateDestination() {
    final settings = AppSettingsScope.maybeOf(context);
    if (settings != null && settings.hasOnboarded) {
      context.go('/home');
    }
  }

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
              AppPrimaryButton(
                label: 'Get Started',
                onPressed: () {
                  final settings = AppSettingsScope.maybeOf(context);
                  if (settings != null && settings.hasOnboarded) {
                    context.go('/home');
                  } else {
                    context.go('/onboarding');
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Already have an account? Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
