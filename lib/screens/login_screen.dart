import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_text_field.dart';

/// User sign-in screen (Stage 1 placeholder).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    // Stage 1: No real auth backend yet. Direct navigation for layout testing.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Stage 1 preview: Signed in as demo user.'),
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
        leading: BackButton(onPressed: () => context.go('/splash')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Enter your credentials to resume your study sessions.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              AppTextField(
                controller: _emailController,
                label: 'Email',
                hintText: 'name@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.mail_outline_rounded, size: AppSpacing.iconSm),
              ),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                controller: _passwordController,
                label: 'Password',
                hintText: '••••••••',
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
              const SizedBox(height: AppSpacing.sm),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              AppPrimaryButton(
                label: 'Sign In',
                onPressed: _handleSignIn,
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account?',
                    style: theme.textTheme.bodySmall,
                  ),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('Register'),
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
