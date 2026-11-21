# Stage 4: Authentication and Guest Mode

Only modify files for this feature. Do not edit README.md, the theme, firestore.rules, firestore.indexes.json, or tools/seed/. Do not add fake buttons or invented data. Do not run deploy or seed commands. Work only on the current branch (`stage-4-auth`), commit there, and push that branch. Run `flutter analyze` and `flutter test` when you are done.

## Scope
- Implement email/password registration, sign in, forgot password, and sign out using `AuthRepository` (`FirebaseAuthRepository`) and `AuthController` (`ChangeNotifier` + `AppAuthScope`).
- Synchronize `users/{uid}` profile document (`displayName`, `nativeLanguageCode`, `targetLanguageCode`, `preferences`, `createdAt`) on sign-in and registration via `ProfileRepository`.
- Support full guest browsing across Home, Categories, Category Phrases, Phrase Study, Search, and Profile.
- Provide `requireSignIn` modal bottom sheet for account-only actions and declarative `GoRouter` route guards for Splash, Onboarding, Login, Register, and Forgot Password.
- Map Firebase Auth error codes to friendly, privacy-preserving messages (one generic message for wrong password or unknown account; neutral confirmation for password reset).
