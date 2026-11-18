import 'package:material_ui/material_ui.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PhrasePracticeApp());
}

/// Root widget for Phrase Practice configuring theme, typography, and declarative routing.
class PhrasePracticeApp extends StatelessWidget {
  const PhrasePracticeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Phrase Practice',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Switchable automatically by system setting
      routerConfig: appRouter,
    );
  }
}
