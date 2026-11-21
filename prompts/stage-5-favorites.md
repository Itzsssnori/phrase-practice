# Stage 5: Favorites and Learning Progress Sync

Only modify files for this feature. Do not edit README.md, the theme, firestore.rules, firestore.indexes.json, or tools/seed/. Do not add fake buttons or invented data. Do not run deploy or seed commands. Work only on the current branch (`stage-5-favorites`), commit there, and push that branch. Run `flutter analyze` and `flutter test` when you are done.

## Scope
- Implement `UserPhraseRepository` and `UserPhraseController` (`ChangeNotifier` + `AppUserPhraseScope`) for signed-in users:
  - `users/{uid}/favorites/{phraseSlug}`
  - `users/{uid}/learnedPhrases/{phraseSlug}__{targetLanguageCode}`
  - `users/{uid}/recentPhrases/{phraseSlug}`
- Optimistic updates with in-flight double-tap guards and automatic rollback + user-visible error message on write failure.
- Prompt guests with `requireSignIn` when tapping favorite or mark-as-learned.
- Display Favorites section on Home (with "See all" pushing `/favorites`, empty state, and guest sign-in card) and the full Favorites screen.
- Display Continue Studying (recent phrases) on Home and per-category learned counts.
