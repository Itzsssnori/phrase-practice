# Stage 8: AI Translator

Do not read or use stored CLI tokens or credential files. If you need a credential, stop and ask me.
Do not edit README.md, firestore.rules, firestore.indexes.json, tools/seed/, or the theme tokens. You may update docs/data-model.md for the translationHistory fields. Do not run seed or deploy commands. Do not push to or merge into main. Work only on the current branch (`stage-8-translator`), commit there, and push that branch.
Do not add fake buttons or invented data. Never put an API key anywhere in the app or repo. Run `flutter analyze` and `flutter test` when you are done.

## Scope
- **App Check & SDK**: Initialize `firebase_app_check` in `main.dart` before other Firebase services (`WebDebugProvider` / `AndroidDebugProvider` / `AppleDebugProvider` in debug; `ReCaptchaEnterpriseProvider` via `--dart-define=APP_CHECK_WEB_SITE_KEY` / Play Integrity / App Attest in release). Mark translator unavailable if release web site key is missing.
- **Translation service**: `TranslatorRepository` + `FirebaseAiTranslatorRepository` using `FirebaseAI.googleAI()` with a single model constant (`gemini-3.5-flash-lite`), structured JSON output (`status`: `ok` / `not_a_phrase` / `unsupported`, `translation`, `pronunciation`, `exampleSentence`, `exampleTranslation`, `note`), delimited user input, 2–200 char validation, 30s timeout, friendly error mapping (429/quota, safety blocked, network, permission, timeout), 3-second minimum gap, 60-second quota cooldown, and history-first lookup.
- **Access gates**: Guests see explanation + Sign In / Create Account; signed-in users with unverified email see "Verify your email to use the translator" gate; verified signed-in users can translate.
- **Saved translations & History**: Save each `ok` result to `users/{uid}/translationHistory/{autoId}` with only allowed fields (`inputText`, `sourceLanguageCode`, `targetLanguageCode`, `translatedText`, `pronunciation`, `exampleSentence`, `exampleTranslation`, `note`, `isSaved: false`, `createdAt`). Translator History screen supports All / Saved segments, full result inspection, optimistic `isSaved` star toggle with rollback, delete one with Undo, and batched Clear history.
- **Entry points**: Home "Translate a phrase" card, Search "Can't find it? Translate it" prefill button, and Translator AppBar History action.
