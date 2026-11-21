#!/usr/bin/env node

/**
 * Exports a language's translation file to a reviewer CSV sheet with UTF-8 BOM.
 *
 * Usage:
 *   node tools/seed/review-export.js <code>
 *
 * Writes:
 *   tools/seed/review/<code>.csv
 */

const fs = require('fs');
const path = require('path');

const code = process.argv[2]?.trim();
if (!code) {
  console.error('Usage: node tools/seed/review-export.js <languageCode>');
  process.exit(1);
}

const dataDir = path.join(__dirname, 'data');
const transDir = path.join(dataDir, 'translations');
const reviewDir = path.join(__dirname, 'review');

const phrasesPath = path.join(dataDir, 'phrases.json');
const enPath = path.join(transDir, 'en.json');
const targetPath = path.join(transDir, `${code}.json`);

if (!fs.existsSync(phrasesPath) || !fs.existsSync(enPath)) {
  console.error('Error: Missing data/phrases.json or data/translations/en.json');
  process.exit(1);
}

if (!fs.existsSync(targetPath)) {
  console.error(`Error: Translation file not found: data/translations/${code}.json`);
  process.exit(1);
}

const phrases = JSON.parse(fs.readFileSync(phrasesPath, 'utf8'));
const enMap = JSON.parse(fs.readFileSync(enPath, 'utf8'));
const targetMap = JSON.parse(fs.readFileSync(targetPath, 'utf8'));

const COLUMNS = [
  'slug',
  'category',
  'english',
  'translation',
  'pronunciation',
  'example',
  'note',
  'status',
  'correction_text',
  'correction_pronunciation',
  'correction_example',
  'reviewer_notes',
];

function escapeCsvCell(value) {
  const str = value == null ? '' : String(value);
  if (str.includes('"') || str.includes(',') || str.includes('\n') || str.includes('\r')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

fs.mkdirSync(reviewDir, { recursive: true });

const lines = [COLUMNS.join(',')];

for (const phrase of phrases) {
  const slug = phrase.slug;
  const enEntry = enMap[slug] || {};
  const targetEntry = targetMap[slug] || {};

  const row = [
    slug,
    phrase.categoryId,
    enEntry.text || '',
    targetEntry.text || '',
    targetEntry.pronunciation || '',
    targetEntry.exampleSentence || '',
    targetEntry.meaningNote || '',
    targetEntry.verified === true ? 'ok' : '',
    '',
    '',
    '',
    '',
  ];

  lines.push(row.map(escapeCsvCell).join(','));
}

const outPath = path.join(reviewDir, `${code}.csv`);
// Prepend UTF-8 BOM (\uFEFF) so Microsoft Excel opens CJK and accented characters properly
fs.writeFileSync(outPath, '\uFEFF' + lines.join('\r\n') + '\r\n', 'utf8');
console.log(`✅ Exported ${phrases.length} rows for '${code}' to ${path.relative(process.cwd(), outPath)}`);
