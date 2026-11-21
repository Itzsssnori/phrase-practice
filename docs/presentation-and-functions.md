# Phrase Practice — Functions Reference & Live Presentation Flow

This guide serves two purposes:
1. **Functional Reference:** A complete catalog of how every feature in the project brief (and stretch goal) works under the hood.
2. **Live Presentation & Demo Flow:** A step-by-step script for demonstrating the app smoothly in class, to reviewers, or to stakeholders.

---

## 1. Project Brief Verification Matrix

| Project Brief Requirement | Status | Key Screens & Services | Automated Verification |
|---|---|---|---|
| **Must-Have 1:** Phrase categories such as greetings, food, and directions | **Complete** (20 categories across 3 groups, 200 phrases in `en`, `es`, `fil`, `fr`) | `HomeScreen`, `CategoriesScreen`, `CategoryPhrasesScreen`, `BrowseDataService` | `stage_3_browse_test.dart`, `stage_8_5a_content_infra_test.dart` |
| **Must-Have 2:** Save favorite phrases | **Complete** (Real-time optimistic bookmarking with Undo snackbar & Firestore sync) | `FavoritesScreen`, `AppFavoriteButton`, `UserPhraseController`, `UserPhraseRepository` | `stage_5_favorites_test.dart` |
| **Must-Have 3:** Quiz mode with a score | **Complete** (Setup, 4-option multiple choice, immediate feedback, score & accuracy, Review Mistakes, saved attempts) | `QuizSetupScreen`, `QuizScreen`, `QuizResultScreen`, `ReviewMistakesScreen`, `QuizController` | `stage_6_quiz_test.dart` |
| **Must-Have 4:** Progress screen | **Complete** (Learned count & progress bar per target language, per-category breakdown, 20-attempt quiz stats) | `ProgressScreen`, `ProgressController`, `ProgressCalculator` | `stage_7_progress_settings_test.dart` |
| **Must-Have 5 (AI Feature):** Type any phrase and AI translates it, gives an example sentence, and adds a pronunciation hint | **Complete** (Gemini via Firebase AI Logic with App Check, verified-email gate, history cache reuse, rate limiting) | `TranslatorScreen`, `TranslatorHistoryScreen`, `TranslationResultCard`, `TranslatorController`, `TranslatorRepository` | `stage_8_translator_test.dart`, `stage_8_e2e_checklist_test.dart` |
| **Stretch Idea:** Read phrases aloud with text-to-speech | **Complete** (`flutter_tts` on-device/browser speech engine, locale fallback chain, Normal/Slow speed, Recall Mode listening practice) | `AppAudioButton`, `SpeechService`, `TtsVoiceSelector`, `TtsEngine` | `stage_9_tts_test.dart` |

---

## 2. Core Functions & Feature Catalog

### A. Language Pair & Multi-Script Architecture
- **Bidirectional Language Pair (`LanguageSettingsController`):**
  - Users choose `"I speak"` (native language) and `"I'm learning"` (target language).
  - Selecting the same language for both automatically swaps the pair so native and target languages are never identical.
  - Changes take effect immediately across all screens and persist locally via `SharedPreferences` (and sync to `users/{uid}` when signed in).
- **Script-Aware Rendering (`LocalizedPhraseText`):**
  - Automatically applies canonical `Locale` tags (including `zh-Hans-CN` for Simplified Chinese) and script-prioritized Noto Sans fallback chains (`Noto Sans SC`, `Noto Sans JP`, `Noto Sans KR`, `Noto Sans` for Cyrillic) while keeping Latin scripts in `Inter`.
- **Pronunciation System Labeling:**
  - Every language declares its `pronunciationSystem` (`Respelling`, `Latin transliteration`, `Romaji`, `Revised Romanization`, or `Pinyin`), which labels the pronunciation line across Phrase Cards, Phrase Study, Quiz feedback, and AI Translation results.

### B. Grouped Categories, Home & Per-Script Search
- **Home Screen (`HomeScreen`):**
  - Displays the **Language Pair Chip**, a **Quick Search** entry bar, a **Continue Studying** section (from recent phrases), a **Featured Daily Phrase** card, the top **6 Essential Categories** (with a `"See all"` link), a **Saved Favorites** preview, and a **Translator** shortcut card.
- **Grouped Categories Directory (`CategoriesScreen`):**
  - Organizes all active categories into three ordered groups:
    1. **Everyday Conversations** (`greetings`, `food`, `social-conversations`, `shopping`, `time-dates-numbers`, `communication-help`, `family-relationships`)
    2. **Travel & Navigation** (`directions`, `travel`, `transportation`, `airport-immigration`, `accommodation`, `restrooms`, `sightseeing`, `money-payments`, `weather`)
    3. **Safety & Essential Needs** (`emergencies`, `police-safety`, `health-pharmacy`, `lost-found`)
- **Per-Script Search (`SearchScreen` & `SearchNormalizer`):**
  - Searches target text, native text, pronunciation, and English meaning notes in memory (0 extra Firestore reads).
  - Strips Latin accents/diacritics (`cafe` matches `café`, `cuanto` matches `cuánto`), folds Russian `ё` → `е` (while keeping `й` ≠ `и`), and preserves exact Japanese dakuten (`が` ≠ `か`), Hangul, and Chinese characters.
  - When a query has no matching seed phrase, offers a direct **"Translate it"** button that opens the AI Translator pre-filled with that query.

### C. Phrase Study, Recall Mode & Text-to-Speech (TTS)
- **Full-Context Study View (`PhraseStudyScreen`):**
  - Displays the target translation in large focus typography, the native meaning, the labeled pronunciation guide, a realistic example sentence, cultural/regional notes in English, and a calm draft-translation notice when `verified == false` (highlighted in amber for `critical` safety/medical categories).
- **Reader Controls:**
  - **Text Size (`Aa`):** Cycles through `Default`, `Large`, and `Extra Large` (shared with Settings).
  - **Recall Mode (Eye Icon):** Hides the target translation and pronunciation behind `"Tap to reveal"` cards for active recall practice.
- **Text-to-Speech (`SpeechService` & `AppAudioButton`):**
  - Plays target-language pronunciation for both the main phrase and the example sentence using the device's or browser's built-in speech synthesizer (`flutter_tts`).
  - **Recall Mode Listening Practice:** Tapping the audio button while Recall Mode hides the translation plays the audio **without revealing the hidden text**, enabling pure listening comprehension practice.
  - **Speech Speed Toggle (`Normal` / `Slow`):** Placed right next to the audio button on Phrase Study and synced with Settings (`1.0` vs `0.6` on Web, or mapped to the platform's `getSpeechRateValidRange`).
  - **Safety & Lifecycle Rules:** Never autoplays; only one utterance plays at a time; tapping an active button stops playback; automatically stops on screen disposal, language change, or app backgrounding.

### D. Favorites, Learned Phrases & Progress Tracking
- **Favorites (`FavoritesScreen` & `UserPhraseController`):**
  - One-tap heart button on any phrase card or study screen.
  - Optimistic UI update with a `"Removed from favorites"` + **Undo** snackbar on removal.
  - Guests tapping Favorite or Mark as Learned are prompted with a clean sign-in modal (`requireSignIn`) and return seamlessly after signing in.
- **Learned Phrases (Per Target Language):**
  - Stored under `users/{uid}/learnedPhrases/{phraseSlug}__{targetLanguageCode}` so learning a phrase in Spanish is tracked independently from Filipino or French.
- **Progress Screen (`ProgressScreen` & `ProgressCalculator`):**
  - **Overview Card:** Learned count, total available phrases in the active target language, percentage, and visual progress bar.
  - **By Category:** Per-category learned/total counts and progress bars.
  - **Quiz Performance:** Computed from up to the 20 most recent saved quiz attempts for the active target language (Quizzes Taken, Average Score %, Best Score %, and the 10 most recent attempts list).

### E. Practice Quiz & Review Mistakes
- **Quiz Setup (`QuizSetupScreen`):**
  - Choose **All Categories** or a specific category, **Direction** (*Native → Target* or *Target → Native*), and **Number of Questions** (`5` or `10`, clamped to available phrases).
- **Active Quiz (`QuizScreen`):**
  - 4 unique multiple-choice options per question.
  - Includes a TTS audio button on the question card when testing *Target → Native*, and in the post-answer feedback panel when testing *Native → Target*.
  - Reveals pronunciation and context notes immediately after submitting each answer.
- **Quiz Result & Review Mistakes (`QuizResultScreen` & `ReviewMistakesScreen`):**
  - Displays raw score (`X / Y`), accuracy percentage, supportive summary copy, and every missed phrase comparing the user's answer with the correct answer.
  - **"Review Mistakes"** opens a dedicated study drill for missed phrases with a **"Practice These Again"** button.

### F. AI Translator & Personal Translation History
- **Firebase AI Logic (`TranslatorRepository` & `TranslatorController`):**
  - Uses `FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash-lite')` with a strict `Schema.object` response schema (`status`, `translation`, `pronunciation`, `exampleSentence`, `exampleTranslation`, `note`).
  - No API key is stored anywhere in the app or repo; protected by **Firebase App Check** (`AppCheckService`).
- **Access & Abuse Protections:**
  - Requires a signed-in user with a **verified email** (shows a clear verification/sign-in gate otherwise).
  - Enforces a 200-character input cap, rejects empty/symbol-only inputs, wraps user text in `<user_phrase>...</user_phrase>` delimiters with prompt-injection refusal instructions, and enforces a 3-second minimum gap plus a 10-requests-per-5-minutes client rate limit.
  - **History Cache Reuse:** Checks `users/{uid}/translationHistory` for a matching normalized input + language pair first so repeated translations return immediately with a `"From history"` badge and cost **0 Gemini requests**.
- **Translator History (`TranslatorHistoryScreen`):**
  - Segmented filter for **All** vs. **Saved (Starred)** translations, delete with **Undo**, and **Clear All** confirmation.

### G. Settings, Audio Voices, Privacy & Account Deletion
- **Settings & Profile (`ProfileScreen`):**
  - Account card (display name editing, email verification status & resend with 60s cooldown), Language pair pickers, Theme Mode (`System`, `Light`, `Dark`), Reading controls (`Study Text Size`, `Recall Mode`, `Speech Speed`), and the **Audio voices** availability table with a **Recheck** button.
- **Privacy & Multi-Step Account Deletion (`PrivacyScreen` & `AuthController.deleteAccount`):**
  - Plain-language privacy notice explaining what is stored in Firestore, what stays on device, how Gemini processes translator requests, and how device/browser TTS works.
  - **3-Step Account Deletion:** Warning dialog listing all data to be removed → password re-authentication → final confirmation that deletes every user subcollection (`favorites`, `learnedPhrases`, `recentPhrases`, `quizAttempts`, `translationHistory`), deletes `users/{uid}`, and deletes the Firebase Auth account.

---

## 3. Step-by-Step Presentation & Live Demo Flow (5–7 Minutes)

Use this sequence during your live presentation so every requirement from the project brief and stretch goal is demonstrated naturally.

### Step 1: First Launch & Guest Mode Browsing (1 min)
1. **Start on Home (`/home`) as a Guest:**
   - Point out the calm editorial aesthetic (warm paper tones, high-contrast typography, no noisy gamification).
   - Tap the **Language Pair Chip** at the top (`I speak English • I'm learning Spanish`) to open the **Language Picker Bottom Sheet**. Show that active languages (`English`, `Spanish`, `Filipino`, `French`) display their native names (`English`, `Español`, `Filipino`, `Français`).
2. **Browse Grouped Categories (`/categories`):**
   - Tap **Categories** in the bottom navigation bar (or `"See all"` on Home).
   - Highlight the three thematic groups: **Everyday Conversations**, **Travel & Navigation**, and **Safety & Essential Needs**.
   - Open **Food and Dining** or **Emergencies** to show the phrase cards with target text, native meaning, and labeled pronunciation guide (`Respelling:`).

### Step 2: Phrase Study, Recall Mode & Text-to-Speech Stretch Goal (1.5 mins)
1. **Open Phrase Study (`/phrase-study/:id`):**
   - Tap any phrase card to open **Phrase Study**.
   - Point out the structured layout: Target Translation card, Native Meaning & Pronunciation card, Example Sentence card, Notes card, and the Draft Translation notice at the bottom.
2. **Demonstrate Text-to-Speech (Stretch Goal):**
   - Tap the **Speaker Button** on the main translation card to read the target phrase aloud.
   - Tap the **`Normal` / `Slow`** speed button right next to it to switch to `Slow` (60% speed), then tap the speaker button again so the audience hears the slower pronunciation.
   - Tap the smaller **Speaker Button** on the **Example** card to play the full example sentence.
3. **Demonstrate Recall Mode & Text Scaling:**
   - Tap **`Aa`** in the top app bar to cycle through `Default`, `Large`, and `Extra Large` text sizes.
   - Tap the **Eye Icon** in the top app bar to turn **Recall Mode ON**. Show that the translation and pronunciation are now hidden behind `"Tap to reveal"`.
   - Tap the **Speaker Button** while the text is hidden: point out that audio plays for **listening practice** without revealing the hidden text! Then tap `"Tap to reveal"` to check the answer.

### Step 3: Search & "Translate It" Handoff (30 sec)
1. **Open Search (`/search`):**
   - Type an unaccented query like `cuanto` or `bano` and show that accent-insensitive search immediately finds `¿Cuánto cuesta...?` and `¿Dónde está el baño?`.
   - Type a custom phrase that is not in the phrasebook (e.g., `"Can I bring my dog on the patio?"`) to show the empty state with the **"Translate it"** button.

### Step 4: Sign In, Favorites & Learned Phrases (1 min)
1. **Sign In (`/login` or via Guest Prompt):**
   - Sign in with your verified test account.
2. **Bookmark Favorites & Mark as Learned:**
   - Tap the **Heart Icon** on two phrases and toggle **"Mark as learned"** on Phrase Study.
   - Open the **Favorites** tab (`/favorites`) to show the saved phrases list, remove one to demonstrate the **"Removed from favorites — Undo"** snackbar, and tap **Undo**.

### Step 5: Practice Quiz & Review Mistakes (1 min)
1. **Configure & Play a Quiz (`/quiz`):**
   - Go to the **Quiz** tab, pick a category (or *All Categories*), choose **5 Questions**, and tap **Start Quiz**.
   - Answer a few questions correctly and intentionally miss one question.
   - Point out the immediate constructive feedback, revealed pronunciation, and the **TTS Audio Button** on the question/feedback panel.
2. **Quiz Summary & Review Mistakes (`/quiz/result`):**
   - On the **Practice Summary** screen, show the raw score (`4 / 5`), accuracy (`80%`), and the **Missed Phrases** comparison.
   - Tap **Review Mistakes** to show the focused review drill.

### Step 6: Progress Dashboard (30 sec)
1. **Open the Progress Tab (`/progress`):**
   - Show the **Overview** card (phrases learned out of total in the current target language with percentage and progress bar).
   - Scroll through **By Category** and **Quiz Performance** (showing Quizzes Taken, Average Score, Best Score, and the recent quiz attempt you just completed).

### Step 7: AI Translator & Personal History (1 min)
1. **Translate a Custom Phrase (`/translator`):**
   - Open the **Translator** (from Home, Search, or `/translator`).
   - Type a custom travel phrase (e.g., `"Could we sit at a quiet table near the window?"`) and tap **Translate**.
   - Show the structured Gemini response: **"AI translation"** badge, target translation, pronunciation hint, example sentence + translation, usage note, **TTS Audio buttons** for both the translation and example, **Copy**, and **Save (Star)**.
2. **Demonstrate History Cache Reuse & Guardrails:**
   - Tap **Translate** on the same phrase again (or select it from **History**): point out the **"From history"** badge showing it was served from your Firestore history without making a duplicate Gemini call.
   - Briefly mention the safety guardrails: App Check enforcement, verified-email requirement, 3-second cooldown, and prompt-injection refusal.

### Step 8: Settings, Audio Voices & Privacy (30 sec)
1. **Open Settings & Profile (`/profile`):**
   - Show **Light / Dark / System** theme switching, **Reading** preferences (synced with Phrase Study), and the **Audio voices** table showing which languages have an active TTS voice on the current device/browser.
   - Tap **Privacy** (`/privacy`) to show the plain-language data & privacy summary and point out the **Delete Account** option.
