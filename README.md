# Phrase Practice

A phrasebook app that helps people learn useful phrases in another language.
Built for **language learners and travelers**.

Learners can pick the language they want to learn, browse phrases by category,
study them, save favorites, take quizzes, track progress, and type any phrase
of their own to get an AI translation with an example sentence and a
pronunciation hint.

> This README is the team's single source of truth: what the app is, what is
> done, what is left, and who owns what. **Update it in the same pull request
> that changes the status of something.**

---

## 1. What the app is

### Must-have features (from the project brief)

- Phrase categories such as greetings, food, and directions
- Save favorite phrases
- Quiz mode with a score
- Progress screen
- **AI feature:** type any phrase and the AI translates it, gives an example
  sentence, and adds a pronunciation hint

### Stretch idea

- Read phrases aloud with text-to-speech

### Our design decisions

- **Multiple target languages.** The user chooses which language to learn and
  can switch at any time. Phrases are stored once in English, with translations
  stored separately per language.
- **Calm, content-first design.** Modern, minimal, warm, and readable. The
  phrase and its translation are the visual focus. No heavy gamification, no
  mascot, no gradients.
- **Honest AI.** AI-generated content is labeled "AI translation". We never
  show invented content as if it were real data.
- **Guest mode.** Anyone can browse without an account. Login is required only
  for favorites, progress, and quiz history.

---

## 2. Tech stack

| Area | Choice |
|---|---|
| App | Flutter (plain Flutter, **not** FlutterFlow) |
| Navigation | `go_router` |
| Backend | Supabase (Postgres, Auth, Edge Functions) |
| AI translator | Google Gemini API, called **only** through a Supabase Edge Function |
| Text-to-speech | `flutter_tts` (on-device, free) |
| Local preferences | `shared_preferences` |
| Fonts | Noto Sans (supports many writing systems) |
| Dev tooling | Antigravity with the Dart and Flutter plugin |

---

## 3. Getting started

```bash
# 1. Clone and enter the project
git clone <https://github.com/Itzsssnori/phrase-practice.git> phrase_practice
cd phrase_practice

# 2. Get packages
flutter pub get

# 3. Check your setup (Chrome is enough for now)
flutter doctor

# 4. Run in the browser
flutter run -d chrome
```

Notes:

- You do **not** need the Android or Linux toolchains to work on this yet.
  Chrome is enough. Install Android Studio later if we test on a phone.
- Keep `flutter analyze` clean before every pull request.

### Antigravity setup (each person, once)

1. Open the project folder in Antigravity.
2. Go to **Customizations → Marketplace** and add the **Dart and Flutter** plugin.
3. Start a new conversation and ask the agent to summarize the Dart and Flutter
   tools available. If it lists them, you are set.

---

## 4. Current status

### Done

- [x] **Stage 1: Foundation.** Theme (light and dark), `go_router` navigation,
  placeholder screens, bottom navigation bar, and reusable widgets.

### Prepared, not yet applied

- [ ] **Stage 1.5: Visual refinement and Study Screen.** Warmer color tokens,
  one outlined icon family, category icons, Phrase Study screen with recall
  mode and text-size control. The prompt is ready (see `prompts/`) and will be
  applied when the final design is configured.

### Not started

- [ ] Everything from Stage 2 onward (see the roadmap below).

> Screens currently use clearly marked **placeholder** data. There is no
> backend, no real data, and no network code in the app yet.

---

## 5. Screens

| Screen | Purpose | Stage | Status |
|---|---|---|---|
| Splash / Loading | App start, session check | 1 | Placeholder |
| Onboarding (language picker) | Choose target language on first launch | 1, 3 | Placeholder |
| Login | Sign in | 4 | Placeholder |
| Register | Create account | 4 | Placeholder |
| Forgot Password | Reset password | 4 | Placeholder |
| Home | Entry point, continue studying, search | 3 | Placeholder |
| Categories | Browse all categories | 3 | Placeholder |
| Category Phrases | Phrases in one category | 3 | Placeholder |
| Phrase Study | Translation, pronunciation, example, language | 3 | Placeholder |
| Search | Keyword search, filtered by language | 3 | Placeholder |
| Favorites | Saved phrases | 5 | Placeholder |
| Quiz Setup | Pick category, language, number of questions | 6 | Placeholder |
| Quiz | Multiple-choice questions | 6 | Placeholder |
| Quiz Result | Score and missed phrases | 6 | Placeholder |
| Review Mistakes | Practice missed phrases again | 6 | Placeholder |
| Progress | Phrases learned, quiz history | 7 | Placeholder |
| Profile / Settings | Account, language, theme, text size | 7 | Placeholder |
| Translator | Type any phrase, get AI result | 8 | Placeholder |
| Translator History | Past AI translations, save to favorites | 8 | Placeholder |
| Error / No Connection | Offline and failure state | 10 | Placeholder |

---

## 6. Roadmap

Work **one stage at a time**. Do not start a stage before its dependencies are
merged into `main`.

| # | Stage | What it covers | Depends on |
|---|---|---|---|
| 1 | Foundation | Theme, navigation, placeholder screens, widgets | none (**done**) |
| 1.5 | Visual refinement | Color tokens, icons, Phrase Study screen | 1 |
| 2 | Data foundation | Supabase tables, security rules, seed data for 2-3 languages, Flutter models and repositories | 1 |
| 3 | Browse and search | Home, categories, category phrases, phrase study, search, language picker (persisted) | 2 |
| 4 | Auth | Register, login, forgot password, profile row, guest mode, route guards | 2 |
| 5 | Favorites and history | Favorites, mark as learned, recently studied | 3, 4 |
| 6 | Quiz | Setup, quiz, result, review mistakes, attempt history | 3 |
| 7 | Progress and settings | Progress screen, profile and settings, preferences | 4, 5, 6 |
| 8 | AI translator | Edge Function calling Gemini, translator screen, history, caching, save to favorites | 2, 4 |
| 9 | Text-to-speech | Audio buttons using `flutter_tts` | 3 |
| 10 | Final design and QA | Design pass, loading/empty/error states everywhere, accessibility, testing | all |

---

## 7. Who does what

Replace the placeholders with real names and GitHub handles.

### Nori

- **Stage 2** (data foundation), **Stage 8** (Gemini Edge Function), **Stage 10** (final design and QA)
- Owns the shared files: `lib/theme/`, `lib/router/`, `lib/models/`, and `supabase/migrations/`
- Only the lead changes the database schema. Others request what they need.
- Reviews and merges all pull requests

### Enzo

- **Stage 3:** browse, search, language picker
- **Stage 5:** favorites and learning history
- **Stage 9:** text-to-speech

### Charm

- **Stage 4:** auth
- **Stage 6:** quiz
- **Stage 7:** progress and settings

### Order and dependencies

- Stage 2 must be merged before A or B starts.
- A and B can then work in parallel: browse (A) and auth (B) do not depend on each other.
- Stage 5 (favorites) needs a logged-in user. Until B finishes auth, A can use a stubbed user ID.

---

## 8. Working agreements

### Git

1. `main` is protected. Nobody pushes directly to it.
2. One branch per stage, for example `stage-3-browse`, merged by pull request.
3. `git pull` on `main` before starting each stage.
4. Run `flutter analyze` before opening a pull request. It must be clean.
5. Keep pull requests focused. One stage, one PR.

### Prompting the AI agent

Start **every** prompt with this guard:

```
Only modify files for this feature. Do not edit the theme, router, or models
unless I explicitly say so. Do not change the database schema. Do not add
fake buttons or invented data. Run flutter analyze when you are done.
```

- Keep stage prompts in `prompts/` so everyone uses the same wording.
- Give the agent one stage at a time, never the whole roadmap.
- Run the app and click through the result **before** committing.

### Definition of done (for every pull request)

- [ ] `flutter analyze` has no errors
- [ ] Works in light **and** dark mode
- [ ] Loading, empty, and error states exist
- [ ] No hardcoded colors; uses theme tokens
- [ ] No text clipping or overflow at system text scale 1.5
- [ ] No secrets committed
- [ ] This README's status tables are updated

---

## 9. Data model (proposed for Stage 2)

Phrases are stored once in English. Translations live in a separate table, so
adding a language means adding rows, not changing code.

| Table | Key fields |
|---|---|
| `languages` | code, name, native name, script |
| `categories` | id, name, icon |
| `phrases` | id, category_id, english_text |
| `phrase_translations` | phrase_id, language_code, translated_text, pronunciation, example_sentence |
| `profiles` | user id, selected language, preferences |
| `favorites` | user id, phrase id |
| `learned_phrases` | user id, phrase id, learned at |
| `quiz_attempts` | user id, language, category, score, total, taken at |
| `translation_history` | user id, input text, language, result fields |
| `ai_translation_cache` | input text, language, result fields (saves free-tier quota) |

Security rules (row-level security):

- `languages`, `categories`, `phrases`, `phrase_translations`: readable by everyone, writable only by the lead
- User tables (`profiles`, `favorites`, `learned_phrases`, `quiz_attempts`, `translation_history`): each user can read and write **only their own rows**

This is a proposal. The lead finalizes it in Stage 2.

---

## 10. Secrets and security

- The Supabase URL and anon key may live in the app, but load them from a
  git-ignored config or `--dart-define`.
- **Never** commit the Supabase `service_role` key.
- The **Gemini API key** lives only in the Edge Function's secrets. Never in
  the Flutter app, never in the repo. Anyone can extract a key from an app.
- Add `.env` and any key files to `.gitignore` **before** the first commit.
- Do not log user data or API responses that contain personal information.

---

## 11. What is missing or undecided

These need an answer before or during the stages shown.

| Open item | Needed by | Owner |
|---|---|---|
| Which 2-3 languages to start with | Stage 2 | Team |
| Who checks the translation quality for each language (a speaker should spot-check) | Stage 2 | Team |
| Supabase project created and shared with the team | Stage 2 | Lead |
| Seed content: phrases per category, and how many | Stage 2 | Team |
| Gemini model and free-tier limits (check Google AI Studio, they change) | Stage 8 | Lead |
| Romanization approach for non-Latin scripts (Japanese, Korean, Arabic, etc.) | Stage 2 | Team |
| App name check, icon, and splash design | Stage 10 | Lead |
| Privacy notice and account deletion (the app stores user data) | Stage 7 | Collaborator B |
| Testing on a real phone (needs the Android toolchain) | Stage 10 | Team |

---

## 12. Future suggestions (after the core is done)

Not part of the current scope. Pick these up only when Stage 10 is complete.

- **Spaced repetition:** resurface phrases you struggled with
- **Offline mode:** cache phrases for travelers without a connection
- **Speaking practice:** record the user and compare to the target pronunciation
- **Phrase packs:** downloadable themed sets (airport, restaurant, emergency)
- **Quiz variations:** listening quiz, typing quiz, matching
- **Translator extras:** grammar correction and alternative phrasings
- **Share a phrase** with a friend
- **More languages** as seed content is verified

Deliberately skipped for now: streaks, badges, and leaderboards. The brief asks
for a calm learning experience, and a simple "phrases learned" count is enough.

---

## 13. Changelog

| Date | Change |
|---|---|
| 2026-11-19 | Stage 1 foundation completed; README created |
