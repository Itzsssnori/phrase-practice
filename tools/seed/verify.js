#!/usr/bin/env node

/**
 * Verification script for Phrase Practice seed data.
 *
 * Checks:
 * 1. Languages have required attributes (code, name, nativeName, script, isActive,
 *    sortOrder, ttsLocale, pronunciationSystem) and unique codes.
 * 2. Categories have unique slugs, valid `group` (everyday | travel | safety),
 *    valid `priority` (essential | critical | high), and every ACTIVE category
 *    has at least one ACTIVE phrase (inactive categories may be empty).
 * 3. Phrases have unique slugs, valid `categoryId`, valid difficulty (1..3),
 *    sortOrder, and isActive.
 * 4. For every ACTIVE language, every ACTIVE phrase has a translation in
 *    `data/translations/<code>.json` with non-empty `text`, non-empty `pronunciation`
 *    (except English `en` where `pronunciation` may be empty), non-empty
 *    `exampleSentence`, and English `meaningNote`. Inactive languages require no coverage.
 * 5. Prints coverage per language and the number of unverified rows.
 */

const fs = require('fs');
const path = require('path');

const dataDir = path.join(__dirname, 'data');
const transDir = path.join(dataDir, 'translations');
const languagesFile = path.join(dataDir, 'languages.json');
const categoriesFile = path.join(dataDir, 'categories.json');
const phrasesFile = path.join(dataDir, 'phrases.json');

const VALID_GROUPS = new Set(['everyday', 'travel', 'safety']);
const VALID_PRIORITIES = new Set(['essential', 'critical', 'high']);

function runVerification() {
  console.log('--- Verifying Phrase Practice Seed Data ---');

  if (!fs.existsSync(languagesFile) || !fs.existsSync(categoriesFile) || !fs.existsSync(phrasesFile)) {
    console.error('Error: One or more data JSON files do not exist.');
    process.exit(1);
  }

  const languages = JSON.parse(fs.readFileSync(languagesFile, 'utf8'));
  const categories = JSON.parse(fs.readFileSync(categoriesFile, 'utf8'));
  const phrases = JSON.parse(fs.readFileSync(phrasesFile, 'utf8'));

  const errors = [];

  // 1. Verify Languages
  console.log(`Checking ${languages.length} languages...`);
  const langCodes = new Set();
  for (let i = 0; i < languages.length; i++) {
    const lang = languages[i];
    if (!lang.code || typeof lang.code !== 'string') {
      errors.push(`Language [${i}]: missing or invalid 'code'`);
    } else if (langCodes.has(lang.code)) {
      errors.push(`Duplicate language code: ${lang.code}`);
    } else {
      langCodes.add(lang.code);
    }

    if (
      !lang.name ||
      !lang.nativeName ||
      !lang.script ||
      typeof lang.isActive !== 'boolean' ||
      typeof lang.sortOrder !== 'number' ||
      !lang.ttsLocale ||
      !lang.pronunciationSystem
    ) {
      errors.push(`Language [${lang.code || i}]: missing required attributes`);
    }
  }

  const activeLanguages = languages.filter((l) => l.isActive);

  // 2. Verify Categories
  console.log(`Checking ${categories.length} categories...`);
  const categoryBySlug = new Map();
  for (let i = 0; i < categories.length; i++) {
    const cat = categories[i];
    if (!cat.slug || typeof cat.slug !== 'string') {
      errors.push(`Category [${i}]: missing or invalid 'slug'`);
      continue;
    }
    if (categoryBySlug.has(cat.slug)) {
      errors.push(`Duplicate category slug: ${cat.slug}`);
    }
    categoryBySlug.set(cat.slug, cat);

    if (typeof cat.sortOrder !== 'number' || !cat.iconKey || typeof cat.isActive !== 'boolean') {
      errors.push(`Category [${cat.slug}]: missing or invalid sortOrder, iconKey, or isActive`);
    }
    if (!VALID_GROUPS.has(cat.group)) {
      errors.push(`Category [${cat.slug}]: invalid group '${cat.group}' (must be everyday, travel, or safety)`);
    }
    if (!VALID_PRIORITIES.has(cat.priority)) {
      errors.push(`Category [${cat.slug}]: invalid priority '${cat.priority}' (must be essential, critical, or high)`);
    }
    if (!cat.names || typeof cat.names !== 'object' || !cat.names.en) {
      errors.push(`Category [${cat.slug}]: missing English name in 'names' map`);
    } else if (cat.isActive) {
      for (const activeLang of activeLanguages) {
        if (!cat.names[activeLang.code] || typeof cat.names[activeLang.code] !== 'string') {
          errors.push(`Active category [${cat.slug}]: missing translated name for active language '${activeLang.code}'`);
        }
      }
    }
  }

  // 3. Verify Phrase Structures
  console.log(`Checking ${phrases.length} phrase structures...`);
  const phraseSlugs = new Set();
  const activePhraseCountByCategory = new Map();
  for (const slug of categoryBySlug.keys()) {
    activePhraseCountByCategory.set(slug, 0);
  }

  for (let i = 0; i < phrases.length; i++) {
    const phrase = phrases[i];
    const slug = phrase.slug;
    if (!slug || typeof slug !== 'string') {
      errors.push(`Phrase [${i}]: missing or invalid 'slug'`);
      continue;
    }
    if (phraseSlugs.has(slug)) {
      errors.push(`Duplicate phrase slug: ${slug}`);
    }
    phraseSlugs.add(slug);

    if (!phrase.categoryId || !categoryBySlug.has(phrase.categoryId)) {
      errors.push(`Phrase [${slug}]: categoryId '${phrase.categoryId}' does not exist in categories.json`);
    } else if (phrase.isActive) {
      activePhraseCountByCategory.set(
        phrase.categoryId,
        (activePhraseCountByCategory.get(phrase.categoryId) || 0) + 1
      );
    }

    if (typeof phrase.difficulty !== 'number' || phrase.difficulty < 1 || phrase.difficulty > 3) {
      errors.push(`Phrase [${slug}]: difficulty must be 1, 2, or 3`);
    }
    if (typeof phrase.sortOrder !== 'number' || typeof phrase.isActive !== 'boolean') {
      errors.push(`Phrase [${slug}]: missing sortOrder or isActive`);
    }
    if ('translations' in phrase) {
      errors.push(`Phrase [${slug}]: data/phrases.json must contain structure only (no inline 'translations')`);
    }
  }

  // 4. Verify Active Categories Have >= 1 Active Phrase
  for (const [slug, cat] of categoryBySlug.entries()) {
    const count = activePhraseCountByCategory.get(slug) || 0;
    if (cat.isActive && count === 0) {
      errors.push(`Active category '${slug}' has 0 active phrases assigned!`);
    } else if (cat.isActive) {
      console.log(`  • Active category '${slug}' (${cat.group}/${cat.priority}): ${count} active phrases`);
    }
  }

  // 5. Verify Translations & Coverage per Language
  const activePhrases = phrases.filter((p) => p.isActive);
  console.log('\nLanguage translation coverage:');

  for (const lang of languages) {
    const transPath = path.join(transDir, `${lang.code}.json`);
    const exists = fs.existsSync(transPath);
    if (!exists) {
      if (lang.isActive) {
        errors.push(`Active language '${lang.code}' is missing translation file data/translations/${lang.code}.json`);
      } else {
        console.log(`  • ${lang.code} (${lang.name}) [INACTIVE]: 0 / ${activePhrases.length} active phrases (no file yet)`);
      }
      continue;
    }

    const transMap = JSON.parse(fs.readFileSync(transPath, 'utf8'));
    let coveredCount = 0;
    let unverifiedCount = 0;

    for (const [slug] of Object.entries(transMap)) {
      if (!phraseSlugs.has(slug)) {
        errors.push(`Translation [${lang.code}]: unknown phrase slug '${slug}' not in data/phrases.json`);
      }
    }

    for (const phrase of activePhrases) {
      const entry = transMap[phrase.slug];
      if (!entry) {
        if (lang.isActive) {
          errors.push(`Active phrase [${phrase.slug}] is missing translation in active language '${lang.code}'`);
        }
        continue;
      }

      const hasText = typeof entry.text === 'string' && entry.text.trim().length > 0;
      if (hasText) {
        coveredCount++;
      } else if (lang.isActive) {
        errors.push(`Phrase [${phrase.slug}] [${lang.code}]: empty or missing 'text'`);
      }

      if (entry.verified !== true) {
        unverifiedCount++;
      }

      if (lang.isActive) {
        if (typeof entry.pronunciation !== 'string') {
          errors.push(`Phrase [${phrase.slug}] [${lang.code}]: 'pronunciation' must be a string`);
        } else if (lang.code !== 'en' && entry.pronunciation.trim().length === 0) {
          errors.push(`Phrase [${phrase.slug}] [${lang.code}]: 'pronunciation' must be non-empty for non-English active language`);
        }

        if (typeof entry.exampleSentence !== 'string' || entry.exampleSentence.trim().length === 0) {
          errors.push(`Phrase [${phrase.slug}] [${lang.code}]: missing or empty 'exampleSentence'`);
        }

        if (typeof entry.meaningNote !== 'string' || entry.meaningNote.trim().length === 0) {
          errors.push(`Phrase [${phrase.slug}] [${lang.code}]: missing or empty 'meaningNote'`);
        }

        if (typeof entry.verified !== 'boolean') {
          errors.push(`Phrase [${phrase.slug}] [${lang.code}]: 'verified' must be a boolean`);
        }
      }
    }

    console.log(
      `  • ${lang.code} (${lang.name}) [${lang.isActive ? 'ACTIVE' : 'INACTIVE'}]: ` +
        `${coveredCount} / ${activePhrases.length} active phrases covered, ${unverifiedCount} unverified`
    );
  }

  if (errors.length > 0) {
    console.error(`\n❌ VERIFICATION FAILED with ${errors.length} error(s):`);
    errors.forEach((err, idx) => {
      console.error(`  ${idx + 1}. ${err}`);
    });
    process.exit(1);
  } else {
    console.log(
      `\n✅ VERIFICATION PASSED: ${phrases.length} phrases, ${categories.length} categories ` +
        `(${categories.filter((c) => c.isActive).length} active), and ${languages.length} languages ` +
        `(${activeLanguages.length} active) are valid!`
    );
  }
}

runVerification();
