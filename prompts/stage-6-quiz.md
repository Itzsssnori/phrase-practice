# Stage 6: Practice Quiz

Do not read or use stored CLI tokens or credential files. If you need a credential, stop and ask me.
Do not edit README.md, firestore.rules, firestore.indexes.json, tools/seed/, or the theme tokens. Do not run seed or deploy commands. Do not push to or merge into main. Work only on the current branch (`stage-6-quiz`), commit there, and push that branch.
Do not add fake buttons or invented data. Run `flutter analyze` and `flutter test` when you are done.

## Scope
- Pure Dart `QuizGenerator`: builds 4-option multiple-choice questions from in-memory cached phrases that have translations in both the native and target languages (0 new Firestore reads for questions), drawing 3 unique distractors from the same category first and falling back to other categories, with an injectable `Random`.
- Setup options on Quiz Setup: category or "All categories", question count (5, 10, or 20, capped by pool), direction ("Native to target", "Target to native", or "Mixed"), language pair chip, and recent 5 attempts for signed-in users. Disable Start if pool has fewer than 4 phrases.
- `QuizController` (`ChangeNotifier` + `AppQuizScope`): locks language pair at quiz start, handles immediate answer feedback (color + icon + text + target pronunciation reveal + native context note), exit confirmation dialog, Quiz Result screen, and Review Mistakes screen ("Practice these again" drill).
- `QuizAttemptRepository`: saves one document per finished quiz for signed-in users to `users/{uid}/quizAttempts/{autoId}` with only `targetLanguageCode`, `categoryId`, `score`, `total`, `takenAt` (server timestamp), and `answers`. Guests write nothing.
