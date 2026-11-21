# Phrase Practice

A modern, calm, content-first language-learning mobile and web app built with Flutter.

Phrase Practice focuses on natural language acquisition for **travelers and
curious readers**. It is designed with an editorial, reading-app feel rather
than loud gamification, and emphasizes phrase clarity, accurate cultural
context, and distraction-free study.

Learners choose the language they want to learn (and can switch at any time),
browse phrases across 20 grouped categories, study them with recall mode and
on-device/browser text-to-speech, save favorites, take multiple-choice quizzes,
track progress, and type any phrase of their own to get an AI translation with
an example sentence and a pronunciation hint.

> This README is the team's single source of truth: what the app is, what is
> done, what is left, and who owns what. For a complete feature reference and
> live presentation script, see
> [`docs/presentation-and-functions.md`](docs/presentation-and-functions.md).

---

## 1. What the app is

### Must-have features (from the project brief) — All Implemented & Verified

- [x] **Phrase categories** such as greetings, food, directions, travel, and emergencies (expanded to **20 categories across 3 groups** with **200 phrases**)
- [x] **Save favorite phrases** (per-user Firestore sync with optimistic toggle, undo snackbar, and guest sign-in prompt)
- [x] **Quiz mode with a score** (configurable category, direction, and question count; immediate per-question feedback, score & accuracy summary, review mistakes, and Firestore attempt persistence)
- [x] **Progress screen** (real learned-phrase counts & percentages per target language, per-category breakdown, and quiz performance summary across the 20 most recent attempts)
- [x] **AI feature:** type any phrase and Gemini translates it, gives an example sentence (with source translation), and adds a pronunciation hint + usage note via **Firebase AI Logic**

### Stretch idea — Implemented & Verified

- [x] **Read phrases aloud with text-to-speech** (`flutter_tts` on-device / browser speech engine with per-language voice selection, `Normal` and `Slow` speech speed, voice availability checker in Settings, and listening practice in Recall Mode)

### Design decisions

- **Multiple languages.** Active languages: **English (`en`), Spanish (`es`),
  Filipino (`fil`), and French (`fr`)**, with multi-script infrastructure ready
  for **Russian (`ru`), Japanese (`ja`), Korean (`ko`), and Simplified Chinese (`zh`)**.
  Any active language can be the language a user speaks or the one they are learning.
- **Spanish variety: neutral Latin American Spanish.** Polite *usted/ustedes*,
  no *vosotros* or *voseo*. See [`docs/content-guidelines.md`](docs/content-guidelines.md).
- **Calm, content-first design.** Modern, minimal, warm, and readable. The
  phrase and its translation are the visual focus. No streaks, points, badges,
  leaderboards, mascot, or gradients.
- **Honest AI & honest drafts.** AI-generated content is labeled `"AI translation"`.
  Unreviewed seed translations show a calm draft-translation notice on Phrase Study
  (highlighted in amber for safety-critical categories).
- **Guest mode.** Anyone can browse, study, search, listen to TTS audio, and take
  practice quizzes without an account. Sign-in is required only for saving
  favorites, marking phrases learned, saving quiz attempts, viewing progress,
  and using the AI translator (which also requires a verified email).

---

## 2. Tech stack

| Area | Choice |
|---|---|
| App | Flutter (Dart 3.14+), Material 3. Plain Flutter, **not** FlutterFlow |
| Design system | Custom warm editorial palette (`AppColors`), semantic tokens (`AppSpacing`), Inter + script-aware Noto Sans fallbacks (`LocalizedPhraseText`), accessible contrast, responsive layout |
| State management | `ChangeNotifier` + `InheritedNotifier` scopes (`AppSettingsScope`, `AppAuthScope`, `AppUserPhraseScope`, `AppQuizScope`, `AppProgressScope`, `AppTranslatorScope`, `AppSpeechScope`) |
| Navigation | Declarative routing with `go_router` |
| Backend and database | [Firebase](https://firebase.google.com): Cloud Firestore, Firebase Authentication, and Firebase App Check |
| AI engine | Google Gemini (`gemini-2.5-flash-lite`) through **Firebase AI Logic** (`firebase_ai` client SDK, Gemini Developer API provider) with strict JSON schema output. No API key in the app or repo. |
| Text-to-speech | `flutter_tts` (`^4.2.5`, on-device / browser speech engine, no cloud TTS or API key) |
| Local persistence | `shared_preferences` for language pair, theme mode, study text size, recall mode, and speech speed |
| Dev tooling | Antigravity with the Dart and Flutter plugin |

---

## 3. Getting started

### Prerequisites

- Flutter SDK 3.50.0 or later
- Chrome (for web development and testing)
- Android SDK or Xcode, when testing on a phone or emulator
- Node.js, only for running the seed and review scripts in `tools/seed`

### Run the app

```bash
# Clone and enter the project
git clone https://github.com/Itzsssnori/phrase-practice.git
cd phrase-practice

# Fetch dependencies
flutter pub get

# Run in the browser
flutter run -d chrome
```

### Static analysis and tests

```bash
flutter analyze
flutter test
```

- `flutter analyze`: **0 issues**
- `flutter test`: **185 tests passing** (unit, widget, multi-script rendering, and responsive overflow matrix across 320px–1280px and 1.0x–2.0x text scales)

---

## 4. Project structure

```text
lib/
├── content/
│   └── privacy_copy.dart   # Plain-language Privacy screen copy
├── firebase_options.dart   # FlutterFire generated platform configuration
├── main.dart               # App entrypoint, Firebase + App Check initialization, InheritedNotifier scopes
├── models/                 # Domain entities (Language, Category, Phrase, PhraseTranslation, UserProfile, Quiz, QuizAttempt, TranslationEntry)
├── router/                 # GoRouter route declarations and navigation shell
├── screens/                # All 20+ UI screens (Home, Categories, CategoryPhrases, PhraseStudy, Search, Favorites, QuizSetup, Quiz, QuizResult, ReviewMistakes, Progress, Profile/Settings, Privacy, Translator, TranslatorHistory, Auth, Error, Debug)
├── services/               # Controllers, repositories, SearchNormalizer, TranslatorLanguageGuidance, SpeechService, TtsVoiceSelector, AppCheckService
├── theme/                  # Semantic tokens (AppColors, AppTypography, AppSpacing, AppTheme)
└── widgets/                # Reusable design system components & InheritedNotifier scopes
docs/
├── content-guidelines.md         # Per-language style, script, pronunciation, and CSV review workflow
├── data-model.md                 # Firestore database architecture and schemas
└── presentation-and-functions.md # Complete functional guide & live demo presentation flow
tools/
└── seed/                   # Node.js seed.js, verify.js, check-script.js, review-export.js, review-import.js, and JSON datasets
firestore.rules             # Firestore security rules
firestore.indexes.json      # Composite indexes
firebase.json               # Firebase configuration
```

---

## 5. Firestore data architecture

All translations are embedded inside each phrase document, so switching
languages requires **0 extra phrase reads**. Content documents use their slug
as the document ID so seeding is repeatable. Full details are in
[`docs/data-model.md`](docs/data-model.md).

### Public content (read-only for clients)

- `languages/{code}`: 8 configured languages (`en`, `es`, `fil`, `fr` active; `ru`, `ja`, `ko`, `zh` inactive until speaker review) with `name`, `nativeName`, `script`, `isActive`, `sortOrder`, `ttsLocale`, and `pronunciationSystem`.
- `categories/{slug}`: 20 categories grouped into `everyday` (*Everyday Conversations*), `travel` (*Travel & Navigation*), and `safety` (*Safety & Essential Needs*) with `priority` (`essential`, `critical`, `high`) and multi-language `names`.
- `phrases/{slug}`: 200 active phrases (10 per category) with embedded `translations` per language (`text`, `pronunciation`, `meaningNote` always in English, `exampleSentence`, and `verified`).

### User data (private to each signed-in user)

- `users/{uid}`: profile (`displayName`, `nativeLanguageCode`, `targetLanguageCode`, `createdAt`)
- `users/{uid}/favorites/{phraseId}`: bookmarked phrase slugs (`addedAt`)
- `users/{uid}/learnedPhrases/{phraseSlug}__{targetLanguageCode}`: phrases marked as learned per target language (`phraseId`, `targetLanguageCode`, `learnedAt`)
- `users/{uid}/recentPhrases/{phraseId}`: recently studied phrases (`lastViewedAt`)
- `users/{uid}/quizAttempts/{attemptId}`: quiz scores and per-question answers (`targetLanguageCode`, `categoryId`, `score`, `total`, `takenAt`, `answers`)
- `users/{uid}/translationHistory/{id}`: personal AI translation history (`inputText`, `sourceLanguageCode`, `targetLanguageCode`, `translatedText`, `pronunciation`, `exampleSentence`, `exampleTranslation`, `note`, `isSaved`, `createdAt`)

---

## 6. Security rules

Defined in [`firestore.rules`](firestore.rules):

- `languages`, `categories`, `phrases`: public read, **no client writes**
- `users/{uid}` and its subcollections (`favorites`, `learnedPhrases`, `recentPhrases`, `quizAttempts`, `translationHistory`): read and write **only by the signed-in owner** (`request.auth.uid == uid`) with strict field validation
- Everything else is **denied by default**

---

## 7. Current status

### Completed Stages

- [x] **Stage 1 & 1.5: Foundation & Visual Refinement.** Warm editorial theme (light and dark), `go_router` navigation, bottom navigation shell, reusable widgets, Phrase Study recall mode and text-size scaling.
- [x] **Stage 2: Data Foundation.** Firestore schema, security rules, composite indexes, seed & verification scripts, models, repositories, and debug data verification route.
- [x] **Stage 3: Real Data & Browse.** Categories, Category Phrases, Phrase Study, accent-insensitive Search, Onboarding, and Language Picker wired to Firestore with in-memory session caching and `SharedPreferences` persistence.
- [x] **Stage 4: Authentication & Guest Mode.** Email/password sign-in, registration, password reset, guest mode browsing, `requireSignIn` modal flow, and bidirectional language sync with `users/{uid}`.
- [x] **Stage 5: Favorites, Learned & Recent Phrases.** Optimistic favorites with undo snackbar, per-language learned phrases (`{phraseSlug}__{targetLanguageCode}`), recent phrases tracking, and Home screen sections.
- [x] **Stage 6: Practice Quiz.** Quiz Setup (category, direction, question count), interactive Quiz with immediate feedback, Quiz Result summary, Review Mistakes drill, and Firestore `quizAttempts` persistence for signed-in users.
- [x] **Stage 7: Progress, Settings, Privacy & Account Deletion.** Real-data Progress tab, Profile/Settings screen (display name editing, email verification with 60s cooldown, theme mode, study text size, recall mode), plain-language Privacy screen, and multi-step re-authenticated account + subcollection deletion.
- [x] **Stage 8: AI Translator.** Gemini (`gemini-2.5-flash-lite`) via Firebase AI Logic with App Check initialization, verified-email gate, history reuse before calling Gemini, prompt-injection & length validation, 3s gap / 10-per-5-min rate limiting, Translator History with All/Saved filter, delete with Undo, and Clear All.
- [x] **Stage 8.5a, 8.5b & 8.5c-fr: Multi-Language & Category Expansion.** 8-language & 20-category infrastructure, 200 active phrases across 20 grouped categories in English, Spanish, Filipino, and French, per-script search normalization (`SearchNormalizer`), script-aware typography (`LocalizedPhraseText`), draft-translation notice, and CSV speaker-review tools (`review-export.js`, `review-import.js`, `check-script.js`).
- [x] **Stage 9: Text-to-Speech.** On-device/browser speech synthesis via `flutter_tts` (`4.2.5`), pure locale fallback voice selector (`TtsVoiceSelector`), `Normal`/`Slow` speech speed synced between Settings and Phrase Study, listening practice in Recall Mode, audio buttons on Phrase Study, Translator Result, and Quiz, and the Settings `Audio voices` availability card.
- [x] **Stage 10: Final Design & QA Pass.** Verified loading, empty, and error states across all screens, WCAG accessibility semantics and 48x48 px touch targets, App Check startup integration, and 185 automated tests.

---

## 8. Screens

| Screen | Purpose | Stage | Status |
|---|---|---|---|
| Splash / Loading | App start, session & onboarding check | 4 | **Done** |
| Onboarding | Choose native and target language on first launch | 3 | **Done** |
| Login | Email/password sign-in with validation & guest fallback | 4 | **Done** |
| Register | Account creation with profile initialization | 4 | **Done** |
| Forgot Password | Firebase password reset email flow | 4 | **Done** |
| Home | Featured phrase, continue studying, top 6 essential categories, favorites preview | 3, 5, 8.5a | **Done** |
| Categories | All active categories grouped into Everyday, Travel, and Safety | 3, 8.5a | **Done** |
| Category Phrases | Ordered phrases in a category with learned badges & favorites | 3, 5 | **Done** |
| Phrase Study | Target translation, TTS audio + speed toggle, recall mode, pronunciation system label, example sentence + audio, meaning notes, draft notice | 3, 5, 8.5a, 9 | **Done** |
| Search | Per-script normalized search with category chips & "Translate it" CTA | 3, 8, 8.5a | **Done** |
| Favorites | Saved phrases in current target language with one-tap removal & undo | 5 | **Done** |
| Quiz Setup | Choose category, direction, and question count (5 or 10) | 6 | **Done** |
| Quiz | Multiple-choice questions with TTS audio and immediate constructive feedback | 6, 9 | **Done** |
| Quiz Result | Score, accuracy percentage, missed phrases list, and save-retry banner | 6 | **Done** |
| Review Mistakes | Study cards for missed phrases + focused repeat quiz | 6 | **Done** |
| Progress | Learned count/bar per language, per-category progress, and 20-attempt quiz stats | 7 | **Done** |
| Profile / Settings | Account, email verification, language pair, theme, study text size, recall mode, speech speed, audio voices availability | 7, 9 | **Done** |
| Privacy | Plain-language overview of stored data, AI processing, TTS engine, and deletion | 7, 8, 9 | **Done** |
| Translator | Verified-user AI translation with pronunciation, example, note, TTS audio, copy, save | 8, 9 | **Done** |
| Translator History | All/Saved segmented history with reuse, swipe-to-delete + undo, and clear all | 8 | **Done** |
| Error / Offline | Friendly database connection notice with retry | 10 | **Done** |
| Debug Data (debug builds only) | Live Firestore data-layer inspection route | 2 | **Done** |

---

## 9. Seed, verification, and review tools (`tools/seed/`)

Verify the seed dataset locally (no credentials required):

```bash
node tools/seed/verify.js
node tools/seed/check-script.js fr
```

Export and import native-speaker review sheets (UTF-8 CSV with BOM for Excel/Google Sheets):

```bash
# Export unverified/all phrases for a language to tools/seed/review/<code>.csv
node tools/seed/review-export.js es
node tools/seed/review-export.js fil
node tools/seed/review-export.js fr

# Dry-run import of a reviewed CSV
node tools/seed/review-import.js tools/seed/review/es.csv

# Apply reviewed corrections and set verified: true
node tools/seed/review-import.js tools/seed/review/es.csv --apply
```

Seed Firestore without creating a service account key file (lead only):

```bash
gcloud auth application-default login
cd tools/seed && npm install
GOOGLE_CLOUD_PROJECT=phrase-practice node seed.js
gcloud auth application-default revoke
```

---

## 10. Changelog

| Date | Change |
|---|---|
| 2026-11-19 | Stage 1 & 1.5 completed; Stage 2 data foundation implemented |
| 2026-11-20 | Stages 3 to 7 completed (real browse & search, auth & guest mode, favorites/learned/recent sync, practice quiz, progress & settings, privacy & account deletion) |
| 2026-11-21 | Stage 8 (AI Translator via Firebase AI Logic + App Check), Stage 8.5a/b/c-fr (8-language & 20-category infrastructure, 200 phrases in `en`/`es`/`fil`/`fr`, review tools), Stage 9 (Text-to-Speech via `flutter_tts`), and Stage 10 QA pass completed |
