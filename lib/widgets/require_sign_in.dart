import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_secondary_button.dart';
import 'app_auth_scope.dart';

/// Checks whether the user is authenticated.
///
/// If authenticated, immediately returns `true`.
/// If the user is exploring as a guest, presents an approachable sign-in modal
/// bottom sheet with options to Sign In or Create an Account, and returns `false`.
Future<bool> requireSignIn(
  BuildContext context, {
  String title = 'Sign in to use this feature',
  String message =
      'Create a free account or sign in to sync your progress, favorites, and study notes across devices.',
}) async {
  final auth = AppAuthScope.maybeOf(context);
  if (auth != null && auth.isSignedIn) {
    return true;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusCard)),
    ),
    builder: (modalContext) {
      final theme = Theme.of(modalContext);
      final isDark = theme.brightness == Brightness.dark;

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sheet handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Icon badge
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkPrimaryContainer : AppColors.lightPrimaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: theme.colorScheme.primary,
                    size: AppSpacing.iconLg,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Explanation
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Action buttons
              AppPrimaryButton(
                label: 'Sign In',
                onPressed: () {
                  Navigator.of(modalContext).pop();
                  context.push('/login');
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              AppSecondaryButton(
                label: 'Create Account',
                onPressed: () {
                  Navigator.of(modalContext).pop();
                  context.push('/register');
                },
              ),
              const SizedBox(height: AppSpacing.xs),

              TextButton(
                onPressed: () => Navigator.of(modalContext).pop(),
                child: const Text('Continue Exploring'),
              ),
            ],
          ),
        ),
      );
    },
  );

  return false;
}
