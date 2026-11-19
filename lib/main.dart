import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'services/auth_controller.dart';
import 'services/language_settings_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/app_auth_scope.dart';
import 'widgets/app_error_message.dart';
import 'widgets/app_settings_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsController = LanguageSettingsController();
  await settingsController.load();

  String? initError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    initError = error.toString();
  }

  final authController = AuthController(
    languageSettingsController: settingsController,
  );

  runApp(PhrasePracticeApp(
    initializationError: initError,
    settingsController: settingsController,
    authController: authController,
  ));
}

/// Root widget for Phrase Practice configuring theme, typography, and declarative routing.
class PhrasePracticeApp extends StatefulWidget {
  final String? initializationError;
  final LanguageSettingsController? settingsController;
  final AuthController? authController;

  const PhrasePracticeApp({
    super.key,
    this.initializationError,
    this.settingsController,
    this.authController,
  });

  @override
  State<PhrasePracticeApp> createState() => _PhrasePracticeAppState();
}

class _PhrasePracticeAppState extends State<PhrasePracticeApp> {
  late final LanguageSettingsController _settingsController;
  late final AuthController _authController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _settingsController = widget.settingsController ?? LanguageSettingsController();
    _authController = widget.authController ??
        AuthController(languageSettingsController: _settingsController);
    _router = createAppRouter(
      authController: _authController,
      settingsController: _settingsController,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initializationError != null) {
      return AppAuthScope(
        controller: _authController,
        child: AppSettingsScope(
          controller: _settingsController,
          child: MaterialApp(
            title: 'Phrase Practice',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Offline Mode'),
              ),
              body: SafeArea(
                child: AppErrorMessage(
                  title: 'Database Connection Notice',
                  message:
                      'Firebase could not be initialized on this platform:\n${widget.initializationError}\n\nYou can continue exploring offline screens.',
                  retryLabel: 'Retry Initialization',
                  onRetry: () => main(),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AppAuthScope(
      controller: _authController,
      child: AppSettingsScope(
        controller: _settingsController,
        child: MaterialApp.router(
          title: 'Phrase Practice',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: _router,
        ),
      ),
    );
  }
}
