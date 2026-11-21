# Stage 3: Real Data and Browse

Only modify files for this feature. Do not edit README.md, the theme, firestore.rules, firestore.indexes.json, or tools/seed/. Do not add fake buttons or invented data. Do not run deploy or seed commands. Work only on the current branch (`stage-3-browse`), commit there, and push that branch. Run `flutter analyze` and `flutter test` when you are done.

## Scope
- Wire Categories, Category Phrases, Phrase Study, Search, Onboarding, and the language picker to real Firestore data via `BrowseDataService` (in-memory caching for languages, categories, and active phrases).
- Persist native ("I speak") and target ("I'm learning") language choices locally in `shared_preferences` via `LanguageSettingsController` (`ChangeNotifier` + `AppSettingsScope`).
- Enforce that native and target languages are never identical (selecting the same language swaps them automatically).
- Accent-insensitive, case-insensitive local search across phrase text and meaning notes with category filter chips.
- Handle loading, empty, and error states with retry, light and dark mode, semantics labels, and zero overflow at 1.5x–2.0x text scale and narrow widths.
