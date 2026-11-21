# Phrase Practice — Firestore Data Model

This document specifies the complete Cloud Firestore database schema for Phrase Practice.

## Design Principles
1. **Repeatable Seeding with Slugs:** Public content collections (`languages`, `categories`, `phrases`) use deterministic slugs/codes as document IDs. Re-running the seed script overwrites/merges cleanly without creating duplicate documents.
2. **Embedded Multi-Language Phrases:** All translations for a phrase live in a single document under a `translations` map keyed by ISO 639-1 / 639-2 language code (`en`, `es`, `fil`). There are no language-specific fields at the root of a phrase document.
3. **No Global AI Cache:** AI translations are user-specific and saved strictly under the user's private history subcollection.
4. **Client Read-Only Content:** Public content is write-protected; clients can only read. User data is partitioned by `uid` and accessible solely by the authenticated owner.

---

## 1. Public Content Collections

### `languages/{code}`
Document ID is the ISO language code (`en`, `es`, `fil`, `fr`, `ru`, `ja`, `ko`, `zh`).

| Field | Type | Description |
|---|---|---|
| `name` | string | English name of the language (e.g., "Spanish", "Chinese (Mandarin, Simplified)") |
| `nativeName` | string | Endonym / native display name (e.g., "Español", "日本語", "中文（简体）") |
| `script` | string | Writing system / script (`Latin`, `Cyrillic`, `Japanese`, `Hangul`, `Han (Simplified)`) |
| `isActive` | boolean | Controls whether this language is selectable in the app |
| `sortOrder` | number | Display order in language pickers (1-based integer) |
| `ttsLocale` | string | BCP-47 locale tag for text-to-speech (`en-US`, `es-MX`, `fil-PH`, `fr-FR`, `ru-RU`, `ja-JP`, `ko-KR`, `zh-CN`) |
| `pronunciationSystem` | string | Label for the pronunciation line (`Respelling`, `Latin transliteration`, `Romaji`, `Revised Romanization`, `Pinyin`) |

---

### `categories/{slug}`
Document ID is the semantic category slug (20 categories across 3 groups).

| Field | Type | Description |
|---|---|---|
| `sortOrder` | number | Display ordering within its group (1-based integer) |
| `iconKey` | string | Plain icon identifier matching the category slug |
| `group` | string | Section group: `everyday` ("Everyday Conversations"), `travel` ("Travel & Navigation"), or `safety` ("Safety & Essential Needs") |
| `priority` | string | Priority tier: `essential` (prioritized on Home), `critical` (safety/medical warning styling for unverified drafts), or `high` |
| `isActive` | boolean | Whether the category is visible in the app |
| `names` | map<string, string> | Map of language code to translated category title (`{"en": "Greetings", "es": "Saludos", "fil": "Mga Pagbati"}`) |

---

### `phrases/{slug}`
Document ID is a unique English-derived kebab-case slug (e.g. `hello-polite`, `where-is-the-bathroom`).
In `tools/seed/data/`, phrase structure is stored in `data/phrases.json` and per-language translations live in `data/translations/<code>.json`; `tools/seed/seed.js` merges them into a single Firestore document with an embedded `translations` map.

| Field | Type | Description |
|---|---|---|
| `categoryId` | string | The category slug referencing `categories/{slug}` |
| `difficulty` | number | Complexity rating: `1` (Beginner), `2` (Intermediate), `3` (Advanced) |
| `sortOrder` | number | Relative order within its category |
| `isActive` | boolean | Visibility flag |
| `translations` | map<string, object> | Map of language code (`en`, `es`, `fil`, etc.) to translation payload |

#### Translation Object Structure:
```json
{
  "text": "Where is the bathroom?",
  "pronunciation": "",
  "meaningNote": "Essential navigational inquiry.",
  "exampleSentence": "Excuse me, where is the bathroom?",
  "verified": false
}
```

| Subfield | Type | Nullable | Description |
|---|---|---|---|
| `text` | string | No | The phrase in the target language's native script (never romanized) |
| `pronunciation` | string | Yes | Pronunciation in the language's `pronunciationSystem` (`Respelling`, `Pinyin`, `Romaji`, `Revised Romanization`, or `Latin transliteration`; may be empty only for English) |
| `meaningNote` | string | Yes | Cultural context, politeness register, or regional note — **always written in English** |
| `exampleSentence` | string | Yes | Practical context sentence in the target language's native script |
| `verified` | boolean | No | Native-speaker verification status (defaults to `false`) |

---

## 2. User Data Collections

All user data is isolated per authenticated user under `users/{uid}`.

### `users/{uid}`
Document ID matches the Firebase Authentication UID (`request.auth.uid`).

| Field | Type | Description |
|---|---|---|
| `displayName` | string / null | User's display name |
| `nativeLanguageCode` | string | Primary language code spoken by user (e.g., "en") |
| `targetLanguageCode` | string | Language code currently being studied (e.g., "es") |
| `preferences` | map<string, any> | User settings (e.g., `{"recallMode": false, "textSize": 0}`) |
| `createdAt` | timestamp | Account creation timestamp |

---

### `users/{uid}/favorites/{phraseId}`
Bookmarked phrases for quick recall. Document ID is the phrase slug.

| Field | Type | Description |
|---|---|---|
| `addedAt` | timestamp | When the user favorited the phrase |

---

### `users/{uid}/learnedPhrases/{phraseSlug}__{targetLanguageCode}`
Mastered phrases tracked per target language. Document ID is composite: `{phraseSlug}__{targetLanguageCode}`.

| Field | Type | Description |
|---|---|---|
| `phraseId` | string | The phrase slug referencing `phrases/{slug}` |
| `targetLanguageCode` | string | Language code in which the phrase was mastered (e.g., "es", "fil") |
| `learnedAt` | timestamp | Server timestamp when phrase was marked as learned |

---

### `users/{uid}/recentPhrases/{phraseId}`
Recent study activity queue. Document ID is the phrase slug.

| Field | Type | Description |
|---|---|---|
| `lastViewedAt` | timestamp | Timestamp of most recent view/practice |

---

### `users/{uid}/quizAttempts/{attemptId}`
Logs of practice quiz completions. Document ID is an auto-generated ID or timestamp string.

| Field | Type | Description |
|---|---|---|
| `targetLanguageCode` | string | The language evaluated during the quiz |
| `categoryId` | string / null | Category slug tested, or `null` for mixed/all topics |
| `score` | number | Number of correct answers |
| `total` | number | Total questions in attempt |
| `takenAt` | timestamp | When quiz was submitted |
| `answers` | list<object> | Array of `{ "phraseId": string, "wasCorrect": boolean }` |

---

### `users/{uid}/translationHistory/{id}`
Personal history of translated queries. Auto-generated ID.

| Field | Type | Description |
|---|---|---|
| `inputText` | string | Original normalized input query |
| `sourceLanguageCode` | string | Source language code (e.g., "en") |
| `targetLanguageCode` | string | Target language code (e.g., "es") |
| `translatedText` | string | Resulting AI translation |
| `pronunciation` | string | Simple readable phonetic respelling (empty string if none) |
| `exampleSentence` | string | Short example sentence in the target language |
| `exampleTranslation` | string | Example sentence translated into the source language |
| `note` | string | Optional short usage or regional note (empty string if none) |
| `isSaved` | boolean | Whether the user starred/saved this translation (defaults to `false`) |
| `createdAt` | timestamp | Server timestamp when the translation was saved |
