import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../screens/categories_screen.dart';
import '../screens/category_phrases_screen.dart';
import '../screens/debug_data_screen.dart';
import '../screens/error_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/phrase_study_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/quiz_result_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/quiz_setup_screen.dart';
import '../screens/register_screen.dart';
import '../screens/review_mistakes_screen.dart';
import '../screens/search_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/translator_history_screen.dart';
import '../screens/translator_screen.dart';
import 'app_scaffold_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Central GoRouter configuration managing top-level flows and indexed tab stacks.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // --- Onboarding & Auth Flow ---
    GoRoute(
      path: '/splash',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    // --- Stateful Tab Shell (5 Primary Tabs) ---
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffoldShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Tab 1: Categories
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/categories',
              builder: (context, state) => const CategoriesScreen(),
            ),
          ],
        ),

        // Tab 2: Quiz Setup
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/quiz',
              builder: (context, state) => const QuizSetupScreen(),
            ),
          ],
        ),

        // Tab 3: Progress
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/progress',
              builder: (context, state) => const ProgressScreen(),
            ),
          ],
        ),

        // Tab 4: Profile / Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // --- Detail / Fullscreen Modals ---
    GoRoute(
      path: '/categories/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final categoryId = state.pathParameters['id'] ?? 'travel';
        return CategoryPhrasesScreen(categoryId: categoryId);
      },
    ),
    GoRoute(
      path: '/phrase-study/:slug',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final slug = state.pathParameters['slug'];
        final categoryId = state.uri.queryParameters['category'];
        return PhraseStudyScreen(
          initialPhraseSlug: slug,
          categoryId: categoryId,
        );
      },
    ),
    GoRoute(
      path: '/phrase-study',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final categoryId = state.uri.queryParameters['category'];
        return PhraseStudyScreen(categoryId: categoryId);
      },
    ),
    GoRoute(
      path: '/favorites',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/quiz/play',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const QuizScreen(),
    ),
    GoRoute(
      path: '/quiz/result',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const QuizResultScreen(),
    ),
    GoRoute(
      path: '/quiz/review-mistakes',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReviewMistakesScreen(),
    ),
    GoRoute(
      path: '/translator',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TranslatorScreen(),
    ),
    GoRoute(
      path: '/translator/history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TranslatorHistoryScreen(),
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/error',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ErrorScreen(),
    ),
    if (kDebugMode)
      GoRoute(
        path: '/debug/data',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DebugDataScreen(),
      ),
  ],
);
