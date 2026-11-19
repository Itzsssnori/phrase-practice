#!/usr/bin/env node

/**
 * Phrase Practice Firestore Seeder
 *
 * Populates Firestore with curated languages, categories, and phrases.
 * Uses document slugs/codes as document IDs and { merge: true } for idempotent execution.
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json"
 *   node seed.js
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
const languages = JSON.parse(fs.readFileSync(path.join(dataDir, 'languages.json'), 'utf8'));
const categories = JSON.parse(fs.readFileSync(path.join(dataDir, 'categories.json'), 'utf8'));
const phrases = JSON.parse(fs.readFileSync(path.join(dataDir, 'phrases.json'), 'utf8'));

async function seed() {
  console.log('🚀 Starting Firestore Seed Process...');

  // --- Seed Languages ---
  console.log(`\nWriting ${languages.length} languages into 'languages/{code}'...`);
  const langBatch = db.batch();
  for (const lang of languages) {
    const { code, ...rest } = lang;
    const docRef = db.collection('languages').doc(code);
    langBatch.set(docRef, { ...rest }, { merge: true });
    console.log(`  ✓ language: ${code} (${lang.name})`);
  }
  await langBatch.commit();

  // --- Seed Categories ---
  console.log(`\nWriting ${categories.length} categories into 'categories/{slug}'...`);
  const catBatch = db.batch();
  for (const cat of categories) {
    const { slug, ...rest } = cat;
    const docRef = db.collection('categories').doc(slug);
    catBatch.set(docRef, { ...rest }, { merge: true });
    console.log(`  ✓ category: ${slug}`);
  }
  await catBatch.commit();

  // --- Seed Phrases ---
  console.log(`\nWriting ${phrases.length} phrases into 'phrases/{slug}'...`);
  // Firestore batches support up to 500 operations; 50 phrases fits in one batch
  const phraseBatch = db.batch();
  for (const phrase of phrases) {
    const { slug, ...rest } = phrase;
    const docRef = db.collection('phrases').doc(slug);
    phraseBatch.set(docRef, { ...rest }, { merge: true });
    console.log(`  ✓ phrase: ${slug} (${phrase.categoryId})`);
  }
  await phraseBatch.commit();

  console.log('\n🎉 SUCCESS: All languages, categories, and phrases have been seeded into Firestore!');
  process.exit(0);
}

seed().catch((error) => {
  console.error('\n❌ Error during Firestore seeding:', error);
  process.exit(1);
});
