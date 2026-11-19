#!/usr/bin/env node

/**
 * Verification script for Phrase Practice seed data.
 * Checks that:
 * 1. All active phrases have all 3 translations: 'en', 'es', 'fil'.
 * 2. Every translation has non-empty text, valid exampleSentence, and verified === false.
 * 3. Every phrase's categoryId exists in categories.
 * 4. No category is empty.
 * 5. Document slugs and language codes are unique.
 */

const fs = require('fs');
const path = require('path');

const dataDir = path.join(__dirname, 'data');
const languagesFile = path.join(dataDir, 'languages.json');
const categoriesFile = path.join(dataDir, 'categories.json');
const phrasesFile = path.join(dataDir, 'phrases.json');

const requiredLanguages = ['en', 'es', 'fil'];

function runVerification() {
  console.log('--- Verifying Phrase Practice Seed Data ---');

  if (!fs.existsSync(languagesFile) || !fs.existsSync(categoriesFile) || !fs.existsSync(phrasesFile)) {
    console.error('Error: One or more data JSON files do not exist.');
    process.exit(1);
  }

  const languages = JSON.parse(fs.readFileSync(languagesFile, 'utf8'));
  const categories = JSON.parse(fs.readFileSync(categoriesFile, 'utf8'));
  const phrases = JSON.parse(fs.readFileSync(phrasesFile, 'utf8'));

  let errors = [];

  // 1. Verify Languages
  console.log(`Checking ${languages.length} languages...`);
  const langCodes = new Set();
  languages.forEach((lang, i) => {
    if (!lang.code || typeof lang.code !== 'string') {
      errors.push(`Language [${i}]: missing or invalid 'code'`);
    } else {
      if (langCodes.has(lang.code)) {
        errors.push(`Duplicate language code: ${lang.code}`);
      }
      langCodes.add(lang.code);
    }
    if (!lang.name || !lang.nativeName || !lang.script || typeof lang.isActive !== 'boolean') {
      errors.push(`Language [${lang.code || i}]: missing required attributes`);
    }
  });

  requiredLanguages.forEach((req) => {
    if (!langCodes.has(req)) {
      errors.push(`Required language '${req}' is not defined in languages.json`);
    }
  });

  // 2. Verify Categories
  console.log(`Checking ${categories.length} categories...`);
  const categorySlugs = new Set();
  categories.forEach((cat, i) => {
    if (!cat.slug || typeof cat.slug !== 'string') {
      errors.push(`Category [${i}]: missing or invalid 'slug'`);
    } else {
      if (categorySlugs.has(cat.slug)) {
        errors.push(`Duplicate category slug: ${cat.slug}`);
      }
      categorySlugs.add(cat.slug);
    }
    if (typeof cat.sortOrder !== 'number' || !cat.iconKey || typeof cat.isActive !== 'boolean') {
      errors.push(`Category [${cat.slug || i}]: missing or invalid properties`);
    }
    if (!cat.names || typeof cat.names !== 'object') {
      errors.push(`Category [${cat.slug || i}]: missing 'names' map`);
    } else {
      requiredLanguages.forEach((l) => {
        if (!cat.names[l] || typeof cat.names[l] !== 'string') {
          errors.push(`Category [${cat.slug}]: missing translated name for '${l}'`);
        }
      });
    }
  });

  // 3. Verify Phrases
  console.log(`Checking ${phrases.length} phrases...`);
  const phraseSlugs = new Set();
  const categoryUsage = {};
  categorySlugs.forEach((s) => {
    categoryUsage[s] = 0;
  });

  phrases.forEach((phrase, i) => {
    const slug = phrase.slug;
    if (!slug || typeof slug !== 'string') {
      errors.push(`Phrase [${i}]: missing or invalid 'slug'`);
    } else {
      if (phraseSlugs.has(slug)) {
        errors.push(`Duplicate phrase slug: ${slug}`);
      }
      phraseSlugs.add(slug);
    }

    if (!phrase.categoryId || !categorySlugs.has(phrase.categoryId)) {
      errors.push(`Phrase [${slug || i}]: invalid categoryId '${phrase.categoryId}' (does not exist in categories.json)`);
    } else {
      categoryUsage[phrase.categoryId] = (categoryUsage[phrase.categoryId] || 0) + 1;
    }

    if (typeof phrase.difficulty !== 'number' || phrase.difficulty < 1 || phrase.difficulty > 3) {
      errors.push(`Phrase [${slug}]: difficulty must be a number between 1 and 3`);
    }

    if (typeof phrase.sortOrder !== 'number' || typeof phrase.isActive !== 'boolean') {
      errors.push(`Phrase [${slug}]: missing sortOrder or isActive`);
    }

    if (!phrase.translations || typeof phrase.translations !== 'object') {
      errors.push(`Phrase [${slug}]: missing 'translations' object`);
    } else {
      requiredLanguages.forEach((langCode) => {
        const trans = phrase.translations[langCode];
        if (!trans) {
          errors.push(`Phrase [${slug}]: missing translation for required language '${langCode}'`);
        } else {
          if (!trans.text || typeof trans.text !== 'string' || trans.text.trim() === '') {
            errors.push(`Phrase [${slug}] [${langCode}]: empty or missing 'text'`);
          }
          if (trans.pronunciation !== null && typeof trans.pronunciation !== 'string') {
            errors.push(`Phrase [${slug}] [${langCode}]: 'pronunciation' must be a string or null`);
          }
          if (!trans.exampleSentence || typeof trans.exampleSentence !== 'string') {
            errors.push(`Phrase [${slug}] [${langCode}]: missing or invalid 'exampleSentence'`);
          }
          if (trans.verified !== false) {
            errors.push(`Phrase [${slug}] [${langCode}]: 'verified' must explicitly default to false`);
          }
        }
      });
    }
  });

  // 4. Verify No Category is Empty
  categorySlugs.forEach((catSlug) => {
    const count = categoryUsage[catSlug] || 0;
    if (count === 0) {
      errors.push(`Category '${catSlug}' has 0 phrases assigned!`);
    } else {
      console.log(`  • Category '${catSlug}': ${count} phrases`);
    }
  });

  if (errors.length > 0) {
    console.error(`\n❌ VERIFICATION FAILED with ${errors.length} error(s):`);
    errors.forEach((err, idx) => {
      console.error(`  ${idx + 1}. ${err}`);
    });
    process.exit(1);
  } else {
    console.log(`\n✅ VERIFICATION PASSED: All ${phrases.length} phrases, ${categories.length} categories, and ${languages.length} languages are completely valid!`);
  }
}

runVerification();
