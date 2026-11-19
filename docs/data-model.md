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
Document ID is the ISO language code (e.g. `en`, `es`, `fil`).

| Field | Type | Description |
|---|---|---|
| `name` | string | English name of the language (e.g., "Spanish") |
| `nativeName` | string | Endonym / native display name (e.g., "Español") |
| `script` | string | Writing system / script (e.g., "Latin") |
| `isActive` | boolean | Controls whether this language is selectable in the app |

---

### `categories/{slug}`
Document ID is the semantic category slug (e.g. `greetings`, `food`, `directions`, `travel`, `emergencies`).

| Field | Type | Description |
|---|---|---|
| `sortOrder` | number | Display ordering in category lists (1-based integer) |
| `iconKey` | string | Plain icon identifier (`greetings`, `food`, `directions`, `travel`, `emergencies`) |
| `isActive` | boolean | Whether the category is visible in the app |
| `names` | map<string, string> | Map of language code to translated category title (`{"en": "Greetings", "es": "Saludos", "fil": "Pagbati"}`) |

---

### `phrases/{slug}`
Document ID is a unique English-derived kebab-case slug (e.g. `hello-formal`, `where-is-the-bathroom`).

| Field | Type | Description |
|---|---|---|
| `categoryId` | string | The category slug referencing `categories/{slug}` |
| `difficulty` | number | Complexity rating: `1` (Beginner), `2` (Intermediate), `3` (Advanced) |
| `sortOrder` | number | Relative order within its category |
| `isActive` | boolean | Visibility flag |
| `translations` | map<string, object> | Map of language code (`en`, `es`, `fil`) to translation payload |

#### Translation Object Structure:
```json
{
  "text": "Where is the bathroom?",
  "pronunciation": "ware iz the BATH-room",
  "meaningNote": "Standard polite inquiry",
  "exampleSentence": "Excuse me, where is the bathroom?",
  "verified": false
}
```

| Subfield | Type | Nullable | Description |
|---|---|---|---|
| `text` | string | No | The phrase in the target language |
| `pronunciation` | string | Yes | Simple, human-readable phonetic respelling (e.g. "OH-lah") |
| `meaningNote` | string | Yes | Cultural context or nuance note |
| `exampleSentence` | string | Yes | Practical context sentence in the same language |
| `verified` | boolean | No | Human verification status (defaults to `false`) |

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

### `users/{uid}/learnedPhrases/{phraseId}`
Mastered phrases. Document ID is the phrase slug.

| Field | Type | Description |
|---|---|---|
| `learnedAt` | timestamp | Timestamp when phrase was marked as learned |

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
| `inputText` | string | Original input query |
| `sourceLanguageCode` | string | Source language code |
| `targetLanguageCode` | string | Target language code |
| `translatedText` | string | Resulting translation |
| `pronunciation` | string / null | Phonetic respelling if available |
| `exampleSentence` | string / null | Generated example sentence |
| `createdAt` | timestamp | Creation timestamp |
