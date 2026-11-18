import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_error_message.dart';

/// Error / No Connection state screen.
class ErrorScreen extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;

  const ErrorScreen({
    super.key,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Mode'),
      ),
      body: SafeArea(
        child: AppErrorMessage(
          title: 'Unable to reach practice server',
          message: errorMessage ??
              'Check your network connection. In Stage 1, you can continue practicing with all offline local phrases.',
          retryLabel: 'Retry Connection',
          onRetry: onRetry ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Checking connection... Offline phrases ready.'),
                    duration: Duration(seconds: 2),
                  ),
                );
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
        ),
      ),
    );
  }
}
