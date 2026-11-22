# Phrase Practice

A modern, calm, content-first language-learning mobile app built with Flutter.

Phrase Practice focuses on natural language acquisition for **travelers and
curious readers**. It is designed with an editorial, reading-app feel rather
than loud gamification, and emphasizes phrase clarity, accurate cultural
context, and distraction-free study.

Learners choose the language they want to learn (and can switch at any time),
browse phrases by category, study them, save favorites, take quizzes, track
progress, and type any phrase of their own to get an AI translation with an
example sentence and a pronunciation hint.

> This README is the team's single source of truth: what the app is, what is
> done, what is left, and who owns what. **Update it in the same pull request
> that changes the status of something.** AI agents must not rewrite it unless
> the prompt explicitly asks for it.

---

## 1. What the app is

### Must-have features (from the project brief)

- Phrase categories such as greetings, food and directions
- Save favorite phrases
- Quiz mode with a score
- Progress screen
- **AI feature:** type any phrase and the AI translates it, gives an example
  sentence, and adds a pronunciation hint

### Stretch idea

- Read phrases aloud with text-to-speech

### Design decisions

- **Multiple languages.** Starting languages: **English (`en`), Spanish (`es`),
  Filipino (`fil`)**. Any of them can be the language a user speaks or the one
  they are learning. Adding a language later means adding data, not changing
  code.
- **Spanish variety: neutral Latin American Spanish.** See section 14.
- **Calm, content-first design.** Modern, minimal, warm, and readable. The
  phrase and its translation are the visual focus. No heavy gamification, no
  mascot, no gradients.
- **Honest AI.** AI-generated content is labeled "AI translation". We never
  show invented content as if it were real data.
- **Guest mode.** Anyone can browse without an account. Login is required only
  for favorites, progress, quiz history, and the translator.

---

## 2. Tech stack

| Area | Choice |
|---|---|
| App | Flutter (Dart 3.14+), Material 3. Plain Flutter, **not** FlutterFlow |
| Design system | Custom warm editorial palette, semantic tokens, Inter typography via `google_fonts`, accessible contrast, responsive layout |
| Navigation | Declarative routing with `go_router` |
| Backend and database | [Firebase](https://firebase.google.com): Cloud Firestore and Firebase Authentication |
| AI engine | Google Gemini through **Firebase AI Logic** (client SDK, Gemini Developer API free tier on the Spark plan) for context-aware translations, grammatical breakdown, and cultural notes. No API key in the app. |
| Text-to-speech | `flutter_tts` (on-device, free) |
| Local persistence | `shared_preferences` for recall mode and reader settings |
| Dev tooling | Antigravity with the Dart and Flutter plugin |

---

## 3. Getting started

### Prerequisites

- Flutter SDK 3.50.0 or later
- Chrome (enough for development for now)
- Android SDK or Xcode, only when testing on a phone or emulator
- Node.js, only for running the seed scripts in `tools/seed`

### Run the app

```bash
# Clone and enter the project
git clone https://github.com/Itzsssnori/phrase-practice.git
cd phrase-practice

# Fetch dependencies
flutter pub get

# Check your setup (the Android and Linux items can be ignored for now)
flutter doctor

# Run in the browser
flutter run -d chrome
```

You can also run on a connected device or emulator with `flutter run`.

### Static analysis and tests

```bash
flutter analyze
flutter test
```

### Antigravity setup (each person, once)

1. Open the project folder in Antigravity.
2. Go to **Customizations → Marketplace** and add the **Dart and Flutter** plugin.
3. Start a new conversation and ask the agent to summarize the Dart and Flutter
   tools available. If it lists them, you are set.

Collaborators do **not** need Firebase console access or any service account
key to run the app. `lib/firebase_options.dart` is committed and contains
project identifiers, not secrets.

---

## 4. Project structure

```
lib/
├── firebase_options.dart   # FlutterFire generated platform configuration
├── main.dart               # App entrypoint and Firebase initialization
├── models/                 # Domain entities (Language, Category, Phrase, UserProfile, QuizAttempt)
├── router/                 # GoRouter route declarations and navigation shell
├── screens/                # UI screens (Home, Study, Categories, Quiz, Profile, Translator, Debug)
├── services/               # Repository interfaces and Firestore implementations
├── theme/                  # Semantic tokens (AppColors, AppTypography, AppSpacing, AppTheme)
└── widgets/                # Reusable design system components
docs/
└── data-model.md           # Firestore database architecture and schemas
prompts/                    # Stage prompts, so everyone uses the same wording
tools/
└── seed/                   # Node.js seed scripts and curated phrase datasets
firestore.rules             # Firestore security rules
firestore.indexes.json      # Composite indexes
firebase.json               # Firebase configuration
```

---

## 5. Firestore data architecture

All translations are embedded inside each phrase document, so switching
languages needs no extra reads. Content documents use their slug as the
document ID so seeding is repeatable. Full details are in
[`docs/data-model.md`](docs/data-model.md).

### Public content (read-only for clients)

- `languages/{code}`: active languages (`en`, `es`, `fil`)
- `categories/{slug}`: thematic phrase groupings with multi-language name maps
- `phrases/{slug}`: core phrases with every translation embedded (text,
  pronunciation respelling, meaning note, example sentence, `verified` flag)

### User data (private to each signed-in user)

- `users/{uid}`: profile, native language, target language, preferences
- `users/{uid}/favorites/{phraseId}`: saved phrases
- `users/{uid}/learnedPhrases/{phraseId}`: phrases marked as learned
- `users/{uid}/recentPhrases/{phraseId}`: recently studied phrases
- `users/{uid}/quizAttempts/{attemptId}`: session scores and per-phrase answers
- `users/{uid}/translationHistory/{id}`: personal AI translation history

### Design notes

- Search loads the active phrases once, caches them in memory, and filters
  locally (case-insensitive, accent-insensitive). This is fine for hundreds of
  phrases. Thousands of phrases would need a different approach.
- Repositories return a result type that distinguishes **success, empty, and
  error**. Screens must handle all three.
- There is no global AI translation cache. Results are saved per user in
  `translationHistory`.

---

## 6. Security rules

Defined in `firestore.rules`:

- `languages`, `categories`, `phrases`: public read, **no client writes**
- `users/{uid}` and its subcollections: read and write **only by the signed-in
  owner** (`request.auth.uid == uid`)
- `users/{uid}` writes validate `nativeLanguageCode` and `targetLanguageCode`
- Everything else is **denied by default**

Rules are reviewed by the lead before every deploy and tested in the Firebase
**Rules Playground**. Collaborators do not edit `firestore.rules` without the
lead's approval.

---

## 7. Current status

### Done

- [x] **Stage 1: Foundation.** Theme (light and dark), `go_router` navigation,
  20 placeholder screen shells, bottom navigation bar, reusable widgets.
- [x] **Stage 1.5: Visual refinement.** Warm editorial theme, icons, Phrase
  Study screen with recall mode and text-size control. The **final design
  pass** still happens in Stage 10.
- [x] **Stage 2 code:** Firestore schema, security rules, indexes, seed tools
  with 50 phrases in three languages, models, repositories, debug data route,
  and unit tests. `flutter analyze` and `flutter test` pass.

### Stage 2 checklist (lead)

- [x] Rules reviewed and tested in the Rules Playground / API deny checks
- [x] Rules and indexes deployed
- [x] Seed script run against the Firebase project, service account key deleted
- [x] `/debug/data` verified with real languages, categories, and phrases
- [x] Spanish phrases revised to neutral Latin American Spanish
- [ ] Spanish and Filipino phrases reviewed by a native speaker
- [x] Merged into `main`

### Not started

- [ ] Stage 3 onward (see the roadmap)

> Screens still use clearly marked **placeholder** data until Stage 3 wires
> them to Firestore.

---

## 8. Screens

| Screen | Purpose | Stage | Status |
|---|---|---|---|
| Splash / Loading | App start, session check | 4 | Shell |
| Onboarding (language picker) | Choose native and target language on first launch | 3 | Shell |
| Login | Sign in | 4 | Shell |
| Register | Create account | 4 | Shell |
| Forgot Password | Reset password | 4 | Shell |
| Home | Entry point, continue studying, search | 3 | Shell |
| Categories | Browse all categories | 3 | Shell |
| Category Phrases | Phrases in one category | 3 | Shell |
| Phrase Study | Translation, pronunciation, example, language; recall mode | 3 | Shell (recall mode and text size done) |
| Search | Keyword search, filtered by language | 3 | Shell |
| Favorites | Saved phrases | 5 | Shell |
| Quiz Setup | Pick category, language, number of questions | 6 | Shell |
| Quiz | Multiple-choice questions | 6 | Shell |
| Quiz Result | Score and missed phrases | 6 | Shell |
| Review Mistakes | Practice missed phrases again | 6 | Shell |
| Progress | Phrases learned, quiz history | 7 | Shell |
| Profile / Settings | Account, language, theme, text size | 7 | Shell |
| Translator | Type any phrase, get an AI result | 8 | Shell |
| Translator History | Past AI translations, save to favorites | 8 | Shell |
| Error / No Connection | Offline and failure state | 10 | Shell |
| Debug Data (debug builds only) | Verify the data layer; remove later | 2 | Done |

---

## 9. Roadmap

Work **one stage at a time**. Do not start a stage before its dependencies are
merged into `main`.

| # | Stage | What it covers | Depends on |
|---|---|---|---|
| 1 | Foundation | Theme, navigation, placeholder screens, widgets | none (**done**) |
| 1.5 | Visual refinement | Warm editorial theme, icons, Phrase Study with recall mode | 1 (**done**) |
| 2 | Data foundation | Firestore schema, rules, seed data, models, repositories | 1 (**code done**, see checklist) |
| 3 | Real data and browse | Wire categories, category phrases, phrase study, search, and the language picker to Firestore; persist the language choice | 2 |
| 4 | Auth | Email/password registration and login, forgot password, profile document, guest mode, route guards | 2 |
| 5 | Favorites and progress sync | Favorites, mark as learned, recently studied, sync to the user's account | 3, 4 |
| 6 | Practice quiz | Quiz setup, quiz, result, review mistakes, attempt history | 3 |
| 7 | Progress and settings | Progress screen, profile and settings, preferences | 4, 5, 6 |
| 8 | AI translator | Gemini through Firebase AI Logic: contextual translation, grammatical breakdown, cultural notes, example, pronunciation hint; translator screen, history, save to favorites | 2, 4 |
| 9 | Text-to-speech | Audio buttons using `flutter_tts` | 3 |
| 10 | Final design and QA | Design pass, loading/empty/error states everywhere, accessibility, App Check, testing | all |

---

## 10. Who does what

### Nori (Project Lead)

- **Stage 2** (data foundation), **Stage 8** (Gemini AI translator), **Stage 10** (final design and QA)
- Owns the shared files: `lib/theme/`, `lib/router/`, `lib/models/`,
  `firestore.rules`, `firestore.indexes.json`, and `tools/seed/`
- Only the lead changes the database structure or security rules.
  Others request what they need.
- Owns the Firebase project and its console access
- Reviews and merges all pull requests

### Enzo

- **Stage 3:** real data, browse, search, language picker
- **Stage 5:** favorites and learning history
- **Stage 9:** text-to-speech

### Charm

- **Stage 4:** auth
- **Stage 6:** quiz 
- **Stage 7:** progress and settings

### Order and dependencies

- Stage 2 must be merged (and seeded and deployed) before A or B starts.
- A and B can then work in parallel: browse (A) and auth (B) do not depend on
  each other.
- Stage 5 (favorites) needs a signed-in user. Until B finishes auth, A can use
  a stubbed user ID.

---

## 11. Working agreements

### Git

1. `main` is protected. Nobody pushes directly to it.
2. One branch per stage, for example `stage-3-browse`, merged by pull request.
3. `git pull` on `main` before starting each stage.
4. Run `flutter analyze` and `flutter test` before opening a pull request.
   Both must be clean.
5. Keep pull requests focused. One stage, one PR.
6. Run `git status` before every commit and make sure no key or credential
   file is staged.

### Prompting the AI agent

Start **every** prompt with this guard:

```
Only modify files for this feature. Do not edit README.md, the theme, the
router, the models, firestore.rules, or the database structure unless I
explicitly say so. Do not add fake buttons or invented data. Do not run
deploy or seed commands. Run flutter analyze when you are done.
```

- Keep stage prompts in `prompts/` so everyone uses the same wording.
- Give the agent one stage at a time, never the whole roadmap.
- Read what the agent changed and run the app **before** committing. Agent
  reports are summaries, not proof.

### Definition of done (for every pull request)

- [ ] `flutter analyze` has no errors and `flutter test` passes
- [ ] Works in light **and** dark mode
- [ ] Loading, empty, and error states exist
- [ ] No hardcoded colors; uses theme tokens
- [ ] No text clipping or overflow at system text scale 1.5
- [ ] No secrets committed
- [ ] This README's status tables are updated

---

## 12. Database setup and seeding (lead only)

Verify the seed data locally (no credentials needed):

```bash
node tools/seed/verify.js
```

Seed Firestore:

1. In the Firebase console, go to **Project settings → Service accounts** and
   generate a new private key.
2. Save the key **outside the repo** (for example `~/keys/phrase-practice-admin.json`).
3. Run:
   ```bash
   cd tools/seed
   npm install
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/phrase-practice-admin.json"
   node seed.js
   ```
4. **Delete the key afterwards.** The seed uses merge and slug document IDs,
   so it is safe to re-run.

Review and deploy the rules and indexes:

```bash
cat firestore.rules
firebase deploy --only firestore:rules,firestore:indexes
```

If the CLI asks which project, run `firebase use <your-project-id>` first.
Afterwards, confirm in the console's Firestore **Rules** tab that the deployed
rules are the ones in the repo, and that the database is **not** in open
test mode.

---

## 13. Secrets and security

- `lib/firebase_options.dart` identifies the Firebase project. It is not
  secret, so it is committed. **Rules and App Check** protect the data, not
  the obscurity of this file.
- **Never** commit a service account key or any credential file. The
  `.gitignore` covers common patterns, but check `git status` anyway.
- **No Gemini API key anywhere in the app or repo.** Firebase AI Logic manages
  the key on the server side. Never paste a key into the app code.
- Enable **Firebase App Check** before any public release, and enforce it for
  AI Logic and Firestore. Right now every app is *Unregistered*, which is fine
  while developing. Do not enforce App Check before registering a provider, or
  the app will block its own requests.
- Free tiers have usage limits (Firestore and Gemini). Check the current
  limits before launch, because they change. Add per-user throttling to the
  translator so one user cannot use up the shared quota.
- Do not log user data or API responses that contain personal information.
- Change the default `com.example.*` package names before any real release.
- Use a personal `@gmail.com` account for the Firebase project if a school
  Google account blocks service account key creation.

---

## 14. Content guidelines

- **Spanish: neutral Latin American Spanish.**
  - Use *usted/ustedes* for addressing strangers. No *vosotros* and no voseo.
  - Avoid Spain-only words and expressions.
  - Where regional vocabulary differs a lot, use the most widely understood
    term and mention the main regional alternative in `meaningNote`.
- **Filipino:** conversational Filipino as spoken in everyday settings,
  including *po* for politeness. Where Manila speakers commonly mix in English,
  say so in `meaningNote`.
- **Pronunciation:** a simple readable respelling, for example "OH-lah".
- **`verified`:** every translation starts as `verified: false`. Set it to
  `true` only after a speaker of that language has reviewed it. Agent-written
  translations are drafts.
- Phrases should be natural things a traveler would really say. No awkward
  literal translations.

---

## 15. What is missing or undecided

| Open item | Needed by | Owner |
|---|---|---|
| Firestore mode check (not open test mode) and rules deployed | Stage 2 | Lead |
| Spanish phrases revised to neutral Latin American Spanish | Stage 2 | Lead |
| A Spanish speaker and a Filipino speaker review the seed phrases | Stage 2 | Team |
| Seed script run and service account key deleted | Stage 2 | Lead |
| Gemini model and free-tier limits (check Google AI Studio and the Firebase AI Logic docs, they change) | Stage 8 | Lead |
| App Check registered and enforced | Stage 10 | Lead |
| Bundled Noto font if Japanese, Korean, or Arabic is added (Inter via `google_fonts` is fine for the current Latin-script languages and downloads at runtime) | When adding a language | Team |
| App name check, icon, and splash design; change `com.example.*` package names | Stage 10 | Lead |
| Privacy notice and account deletion (the app stores user data; deleting a user document does not delete its subcollections) | Stage 7 | Collaborator B |
| Testing on a real phone (needs the Android toolchain) | Stage 10 | Team |
| Hardening: explicit rules for each user subcollection instead of a wildcard | Stage 2 | Lead |

---

## 16. Future suggestions (after the core is done)

Not part of the current scope. Pick these up only when Stage 10 is complete.

- **Google Sign-in** as an additional login method (needs extra platform setup)
- **Spaced repetition:** resurface phrases you struggled with
- **Offline mode:** cache phrases for travelers without a connection
- **Speaking practice:** record the user and compare to the target pronunciation
- **Phrase packs:** downloadable themed sets (airport, restaurant, emergency)
- **Quiz variations:** listening quiz, typing quiz, matching
- **Translator extras:** grammar correction and alternative phrasings
- **Share a phrase** with a friend
- **More languages** as seed content is verified (non-Latin scripts need
  romanization and font checks first)

Deliberately skipped for now: streaks, badges, and leaderboards. A simple
"phrases learned" count is enough.

---

## 17. Changelog

| Date | Change |
|---|---|
| 2026-11-19 | Stage 1 and 1.5 completed; Stage 2 data foundation implemented (Firestore, rules, seed data, repositories); README merged into one team guide |