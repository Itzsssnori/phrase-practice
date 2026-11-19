import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../services/auth_validators.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_auth_scope.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_text_field.dart';

/// Password recovery screen.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _submitted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_isLoading) return;
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final authController = AppAuthScope.of(context);
    final result = await authController.sendPasswordReset(_emailController.text.trim());

    if (!mounted) return;

    if (result.isError) {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessageOrNull ?? 'Failed to send reset link. Please try again.';
      });
    } else {
      setState(() {
        _isLoading = false;
        _submitted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Forgot Your Password?',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enter the email address tied to your account and we’ll send you password recovery instructions.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                if (_submitted) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSuccessBackground : AppColors.lightSuccessBackground,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                      border: Border.all(
                        color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.mark_email_read_outlined,
                              color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                              size: 24,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Check Your Email',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'If an account exists for that email, we sent a reset link.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppPrimaryButton(
                    label: 'Return to Sign In',
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/login');
                      }
                    },
                  ),
                ] else ...[
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkErrorBackground : AppColors.lightErrorBackground,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                        border: Border.all(color: theme.colorScheme.error),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  AppTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hintText: 'name@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleReset(),
                    autofillHints: const [AutofillHints.email],
                    enabled: !_isLoading,
                    validator: AuthValidators.validateEmail,
                    prefixIcon: const Icon(Icons.mail_outline_rounded, size: AppSpacing.iconSm),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  AppPrimaryButton(
                    label: 'Send Reset Link',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleReset,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Center(
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/login');
                              }
                            },
                      child: const Text('Back to Sign In'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
