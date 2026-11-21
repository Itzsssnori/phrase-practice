# Phrase Practice — Content & Localization Guidelines

This document defines the content standards, per-language style and pronunciation rules, seed file layout, and native-speaker review workflow for Phrase Practice.

---

## 1. General Phrasebook Principles

1. **Natural Traveler Phrases:** Every phrase must be something a traveler or everyday learner would genuinely say or hear in real life. Avoid awkward, literal word-for-word translations.
2. **Polite Register by Default:** Travelers most often speak with strangers, shopkeepers, transit staff, hotel receptionists, and officials. Always default to the natural polite/courteous register of the target language.
3. **One Phrase per Slug:** Each phrase has a single canonical English-derived kebab-case `slug` (e.g., `where-is-the-bathroom`) assigned to one category in `tools/seed/data/phrases.json`. Never duplicate a phrase across multiple categories.
4. **`meaningNote` Always in English:** Across every language file (`tools/seed/data/translations/<code>.json`), `meaningNote` is **always written in English**. It explains cultural context, register, gender variations, or regional alternatives to the learner in clear English.
5. **Target Text Never Romanized:** The `text` and `exampleSentence` fields (and AI translator `translation` / `exampleSentence` outputs) must always be written in the language's native writing system (`script`). Romanization belongs strictly in `pronunciation`.

---

## 2. Per-Language Rules & Pronunciation Systems

| Code | Language | Native Name | Script | TTS Locale | Pronunciation System | Register & Dialect Rules |
|---|---|---|---|---|---|---|
| `en` | English | English | `Latin` | `en-US` | `Respelling` | Neutral international English. `pronunciation` may be empty (`""`). |
| `es` | Spanish | Español | `Latin` | `es-MX` | `Respelling` | Neutral Latin American Spanish. Use polite **usted** / **ustedes** when addressing strangers or staff. Never use Peninsular *vosotros* or *voseo*. Mention major regional alternatives (e.g., Mexico vs. Southern Cone) in `meaningNote`. |
| `fil` | Filipino | Filipino | `Latin` | `fil-PH` | `Respelling` | Natural conversational Filipino as spoken in everyday life. Include **po** for polite requests and greetings. Note common English loanwords in `meaningNote` where helpful. |
| `fr` | French | Français | `Latin` | `fr-FR` | `Respelling` | Standard international French. Use polite **vous** when addressing strangers or service staff. |
| `ru` | Russian | Русский | `Cyrillic` | `ru-RU` | `Latin transliteration` | Standard Russian in Cyrillic script. Use polite plural/formal **вы** (*vy*) with strangers. Provide clear Latin transliteration in `pronunciation`. |
| `ja` | Japanese | 日本語 | `Japanese` | `ja-JP` | `Romaji` | Polite Japanese (**です / ます** teineigo style) in standard Japanese script (kanji + kana). Use Hepburn romaji in `pronunciation`. |
| `ko` | Korean | 한국어 | `Hangul` | `ko-KR` | `Revised Romanization` | Polite conversational Korean (**해요체** *haeyoche* style, or 합쇼체 where standard for fixed expressions) in Hangul. Use Revised Romanization in `pronunciation`. |
| `zh` | Chinese (Mandarin, Simplified) | 中文（简体） | `Han (Simplified)` | `zh-CN` | `Pinyin` | Standard Mandarin in Simplified Chinese characters (`简体字`). Use polite markers such as **请** (*qǐng*) and **您** (*nín*) where natural. Use Hanyu Pinyin with tone marks (e.g., `Qǐngwèn`) in `pronunciation`. |

---

## 3. Category Groups & Priorities

Every category in `tools/seed/data/categories.json` belongs to one of three ordered groups and carries a priority level:

### Groups (in display order)
1. `everyday` — **"Everyday Conversations"**: `greetings`, `food`, `social-conversations`, `shopping`, `time-dates-numbers`, `communication-help`, `family-relationships`
2. `travel` — **"Travel & Navigation"**: `directions`, `travel`, `transportation`, `airport-immigration`, `accommodation`, `restrooms`, `sightseeing`, `money-payments`, `weather`
3. `safety` — **"Safety & Essential Needs"**: `emergencies`, `police-safety`, `health-pharmacy`, `lost-found`

### Priorities
- `essential` — Shown first in the Home screen's 6-category grid (ordered by group and `sortOrder`).
- `critical` — Safety, medical, and police categories (`emergencies`, `police-safety`, `health-pharmacy`). Unverified phrases in `critical` categories highlight the draft-translation notice on Phrase Study using the theme warning token.
- `high` — Important situational categories available in the grouped Categories directory.

---

## 4. Seed File Layout & Native-Speaker Review Workflow

### File Layout (`tools/seed/`)
- `data/languages.json` — Language metadata (`code`, `name`, `nativeName`, `script`, `isActive`, `sortOrder`, `ttsLocale`, `pronunciationSystem`).
- `data/categories.json` — Category metadata (`slug`, `sortOrder`, `iconKey`, `group`, `priority`, `isActive`, `names`).
- `data/phrases.json` — Phrase structure only (`slug`, `categoryId`, `difficulty`, `sortOrder`, `isActive`).
- `data/translations/<code>.json` — Map of `slug` to `{ "text", "pronunciation", "meaningNote", "exampleSentence", "verified" }`.

### Review Workflow (`verified: false` → `verified: true`)
All drafted or AI-assisted translations start with `"verified": false`. While `"verified"` is `false`, Phrase Study displays a calm draft-translation notice. To review a language with a native speaker:

1. **Export the review sheet (UTF-8 CSV with BOM for Excel compatibility):**
   ```bash
   node tools/seed/review-export.js es
   ```
   This writes `tools/seed/review/es.csv` (ignored by git) with columns:
   `slug, category, english, translation, pronunciation, example, note, status, correction_text, correction_pronunciation, correction_example, reviewer_notes`.

2. **Native speaker fills the sheet:**
   - If a row is accurate and natural, set `status` to **`ok`**.
   - If a row needs changes, set `status` to **`fix`** and fill in `correction_text`, `correction_pronunciation` (optional only for `en`), and `correction_example`.
   - Leave `status` blank for any row not yet reviewed.

3. **Dry-run the import to inspect changes:**
   ```bash
   node tools/seed/review-import.js tools/seed/review/es.csv
   ```
   Malformed rows or `"fix"` rows missing required correction columns are rejected with line-numbered errors.

4. **Apply the import and verify:**
   ```bash
   node tools/seed/review-import.js tools/seed/review/es.csv --apply
   node tools/seed/verify.js
   ```
   - `status: "ok"` sets `"verified": true`.
   - `status: "fix"` replaces `text`, `pronunciation`, and `exampleSentence` with the reviewer's corrections and sets `"verified": true`.
