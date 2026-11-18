import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_text_field.dart';

/// Password recovery screen (Stage 1 placeholder).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleReset() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Stage 1 preview: Password recovery link simulated.'),
        duration: Duration(seconds: 2),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Forgot Your Password?',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Enter the email address tied to your account and we’ll send you recovery instructions.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              AppTextField(
                controller: _emailController,
                label: 'Email Address',
                hintText: 'name@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.mail_outline_rounded, size: AppSpacing.iconSm),
              ),
              const SizedBox(height: AppSpacing.xl),

              AppPrimaryButton(
                label: 'Send Reset Link',
                onPressed: _handleReset,
              ),
              const SizedBox(height: AppSpacing.md),

              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back to Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
