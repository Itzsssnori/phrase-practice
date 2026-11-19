import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../services/browse_data_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_auth_scope.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_secondary_button.dart';
import '../widgets/app_settings_scope.dart';
import '../widgets/language_picker_bottom_sheet.dart';

/// Profile and application settings screen.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _chooseLanguage() async {
    final settings = AppSettingsScope.of(context);
    final languagesResult = await BrowseDataService.instance.getLanguages();
    if (!mounted || languagesResult.isError) return;

    final languages = languagesResult.dataOrNull ?? [];
    final currentTarget = languages.firstWhere(
      (l) => l.code == settings.targetLanguageCode,
      orElse: () => languages.first,
    );

    final selected = await LanguagePickerBottomSheet.show(
      context,
      selectedLanguage: currentTarget,
      title: 'Primary Learning Language',
      availableLanguages: languages,
    );

    if (selected != null && mounted) {
      await settings.setTargetLanguage(selected.code);
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final auth = AppAuthScope.of(context);
      await auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = AppAuthScope.of(context);
    final settings = AppSettingsScope.of(context);

    final isSignedIn = auth.isSignedIn;
    final displayName = auth.displayName ?? (auth.email != null ? auth.email!.split('@').first : 'Learner');
    final email = auth.email ?? '';

    String initials = 'G';
    if (isSignedIn && displayName.isNotEmpty) {
      final parts = displayName.trim().split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = displayName[0].toUpperCase();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Profile'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          children: [
            // Account section: Signed In vs Guest
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: isSignedIn
                    ? Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor:
                                isDark ? AppColors.darkPrimaryContainer : AppColors.lightPrimaryContainer,
                            child: Text(
                              initials,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkOnPrimaryContainer
                                    : AppColors.lightOnPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkText : AppColors.lightText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout_rounded),
                            tooltip: 'Sign Out',
                            onPressed: () => _confirmSignOut(context),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: isDark
                                    ? AppColors.darkPrimaryContainer
                                    : AppColors.lightPrimaryContainer,
                                child: Icon(
                                  Icons.person_outline_rounded,
                                  color: theme.colorScheme.primary,
                                  size: AppSpacing.iconMd,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Guest Explorer',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkText : AppColors.lightText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Sign in to save favorites and track progress.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: AppPrimaryButton(
                                  label: 'Sign In',
                                  onPressed: () => context.push('/login'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: AppSecondaryButton(
                                  label: 'Create Account',
                                  onPressed: () => context.push('/register'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Learning Preferences section (Shell for future stages)
            Text(
              'Learning Preferences',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language_rounded),
                    title: const Text('Target Language'),
                    subtitle: Text('Current: ${settings.targetLanguageCode.toUpperCase()}'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _chooseLanguage,
                  ),
                  Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                  ListTile(
                    leading: const Icon(Icons.history_rounded),
                    title: const Text('Translation History'),
                    subtitle: const Text('View recently translated phrases'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/translator/history'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              'Appearance & Notifications',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.brightness_medium_rounded),
                    title: const Text('Theme Mode'),
                    subtitle: const Text('System Default (Light & Dark supported)'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkPrimaryContainer : AppColors.lightPrimaryContainer,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                      ),
                      child: Text(
                        'System',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkOnPrimaryContainer : AppColors.lightOnPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (isSignedIn) ...[
              const SizedBox(height: AppSpacing.xxl),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
                onPressed: () => _confirmSignOut(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
