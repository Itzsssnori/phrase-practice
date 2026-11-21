#!/usr/bin/env node

/**
 * Phrase Practice Firestore Seeder
 *
 * Merges `data/phrases.json` (structure) with `data/translations/<code>.json`
 * into the existing Firestore document shape (`phrases/{slug}` with an embedded
 * `translations` map), and seeds `languages/{code}` and `categories/{slug}`.
 *
 * Uses document slugs/codes as document IDs and `{ merge: true }` for idempotent execution.
 * Reads credentials strictly from `GOOGLE_APPLICATION_CREDENTIALS`.
 */

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

// 1. Verify GOOGLE_APPLICATION_CREDENTIALS
const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (!credPath) {
  console.error('\n❌ ERROR: GOOGLE_APPLICATION_CREDENTIALS environment variable is not set.');
  console.error('Please set it to the path of your Firebase service account key JSON file:');
  console.error('  export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json"\n');
  process.exit(1);
}

if (!fs.existsSync(credPath)) {
  console.error(`\n❌ ERROR: The file specified by GOOGLE_APPLICATION_CREDENTIALS does not exist:\n  ${credPath}\n`);
  process.exit(1);
}

// 2. Initialize Firebase Admin
try {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
} catch (err) {
  console.error('Failed to initialize Firebase Admin SDK:', err.message);
  process.exit(1);
}

const db = admin.firestore();

// 3. Load Data Files
const dataDir = path.join(__dirname, 'data');
const transDir = path.join(dataDir, 'translations');

const languages = JSON.parse(fs.readFileSync(path.join(dataDir, 'languages.json'), 'utf8'));
const categories = JSON.parse(fs.readFileSync(path.join(dataDir, 'categories.json'), 'utf8'));
const phraseStructures = JSON.parse(fs.readFileSync(path.join(dataDir, 'phrases.json'), 'utf8'));

// Load all available translation files in data/translations/<code>.json
const translationsByLang = {};
if (fs.existsSync(transDir)) {
  for (const file of fs.readdirSync(transDir)) {
    if (file.endsWith('.json')) {
      const code = path.basename(file, '.json');
      translationsByLang[code] = JSON.parse(fs.readFileSync(path.join(transDir, file), 'utf8'));
    }
  }
}

async function commitBatches(operations, batchSize = 450) {
  for (let i = 0; i < operations.length; i += batchSize) {
    const chunk = operations.slice(i, i + batchSize);
    const batch = db.batch();
    for (const op of chunk) {
      batch.set(op.ref, op.data, { merge: true });
    }
    await batch.commit();
  }
}

async function seed() {
  console.log('🚀 Starting Firestore Seed Process...');

  // --- Seed Languages ---
  console.log(`\nWriting ${languages.length} languages into 'languages/{code}'...`);
  const langOps = languages.map((lang) => {
    const { code, ...rest } = lang;
    console.log(`  ✓ language: ${code} (${lang.name}, active=${lang.isActive})`);
    return {
      ref: db.collection('languages').doc(code),
      data: rest,
    };
  });
  await commitBatches(langOps);

  // --- Seed Categories ---
  console.log(`\nWriting ${categories.length} categories into 'categories/{slug}'...`);
  const catOps = categories.map((cat) => {
    const { slug, ...rest } = cat;
    console.log(`  ✓ category: ${slug} (group=${cat.group}, priority=${cat.priority}, active=${cat.isActive})`);
    return {
      ref: db.collection('categories').doc(slug),
      data: rest,
    };
  });
  await commitBatches(catOps);

  // --- Merge & Seed Phrases ---
  console.log(`\nWriting ${phraseStructures.length} phrases into 'phrases/{slug}'...`);
  const phraseOps = phraseStructures.map((phrase) => {
    const { slug, ...structure } = phrase;
    const translations = {};

    for (const [code, langMap] of Object.entries(translationsByLang)) {
      const entry = langMap[slug];
      if (entry) {
        translations[code] = {
          text: entry.text,
          pronunciation: entry.pronunciation ?? '',
          meaningNote: entry.meaningNote ?? '',
          exampleSentence: entry.exampleSentence ?? '',
          verified: typeof entry.verified === 'boolean' ? entry.verified : false,
        };
      }
    }

    console.log(`  ✓ phrase: ${slug} (${phrase.categoryId}) [${Object.keys(translations).join(', ')}]`);
    return {
      ref: db.collection('phrases').doc(slug),
      data: {
        ...structure,
        translations,
      },
    };
  });
  await commitBatches(phraseOps);

  console.log('\n🎉 SUCCESS: All languages, categories, and phrases have been seeded into Firestore!');
  process.exit(0);
}

seed().catch((error) => {
  console.error('\n❌ Error during Firestore seeding:', error);
  process.exit(1);
});
