import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_text_field.dart';

/// User registration screen (Stage 1 placeholder).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Stage 1 preview: Account creation simulated.'),
        duration: Duration(seconds: 2),
      ),
    );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start Your Practice',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Create a clean, ad-free profile to sync your learning progress.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              AppTextField(
                controller: _nameController,
                label: 'Full Name',
                hintText: 'Jane Doe',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: AppSpacing.iconSm),
              ),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                controller: _emailController,
                label: 'Email',
                hintText: 'jane@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.mail_outline_rounded, size: AppSpacing.iconSm),
              ),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                controller: _passwordController,
                label: 'Password',
                hintText: 'At least 8 characters',
                obscureText: _obscurePassword,
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: AppSpacing.iconSm),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: AppSpacing.iconSm,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              AppPrimaryButton(
                label: 'Create Account',
                onPressed: _handleRegister,
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: theme.textTheme.bodySmall,
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
