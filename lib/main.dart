import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'services/language_settings_controller.dart';
import 'theme/app_theme.dart';
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

  runApp(PhrasePracticeApp(
    initializationError: initError,
    settingsController: settingsController,
  ));
}

/// Root widget for Phrase Practice configuring theme, typography, and declarative routing.
class PhrasePracticeApp extends StatelessWidget {
  final String? initializationError;
  final LanguageSettingsController? settingsController;

  const PhrasePracticeApp({
    super.key,
    this.initializationError,
    this.settingsController,
  });

  @override
  Widget build(BuildContext context) {
    final controller = settingsController ?? LanguageSettingsController();

    if (initializationError != null) {
      return AppSettingsScope(
        controller: controller,
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
                message: 'Firebase could not be initialized on this platform:\n$initializationError\n\nYou can continue exploring offline screens.',
                retryLabel: 'Retry Initialization',
                onRetry: () => main(),
              ),
            ),
          ),
        ),
      );
    }

    return AppSettingsScope(
      controller: controller,
      child: MaterialApp.router(
        title: 'Phrase Practice',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // Switchable automatically by system setting
        routerConfig: appRouter,
      ),
    );
  }
}
