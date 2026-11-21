# Stage 7: Progress, Settings, Privacy, and Account Deletion

Do not read or use stored CLI tokens or credential files. If you need a credential, stop and ask me.
Do not edit README.md, firestore.rules, firestore.indexes.json, tools/seed/, or the theme tokens. Do not run seed or deploy commands. Do not push to or merge into main. Work only on the current branch (`stage-7-progress-settings`), commit there, and push that branch.
Do not add fake buttons or invented data. Run `flutter analyze` and `flutter test` when you are done.

## Scope
- **Progress screen**: real per-target-language learned overview, per-category `"X of Y learned"` breakdown in the native language, quiz stats computed from the most recent 20 attempts loaded once per session (and invalidated when a new quiz is saved) with the last 10 attempts listed, recently studied phrase cards, empty state, and guest state.
- **Profile / Settings screen**:
  - Account (signed in): edit display name (validated up to 100 chars, updates only `displayName` in `users/{uid}`).
  - Email verification status (signed in): verified badge or "Verify your email" card with resend cooldown and "I've verified" reload button.
  - Language: "I speak" and "I'm learning" rows opening the language picker.
  - Appearance: Theme Mode (System, Light, Dark) persisted locally in `shared_preferences` and applied to `MaterialApp.themeMode`.
  - Reading: Study Text Size and Recall Mode sharing the exact same `shared_preferences` keys and state as Phrase Study.
- **Privacy screen** (`/privacy`): plain-language summary of what the app stores and how to delete it, kept in `lib/content/privacy_copy.dart` with a lead-review comment.
- **Delete account** (signed in): warning dialog → password re-authentication → final confirmation. Deletes all subcollections in `ProfileRepository.userSubcollections` in batches of up to 500, then `users/{uid}`, then the Firebase Auth user, while suppressing profile re-creation and clearing all per-user controllers.
