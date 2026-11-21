#!/usr/bin/env node

/**
 * Imports a completed native-speaker review CSV sheet into data/translations/<code>.json.
 *
 * Usage:
 *   node tools/seed/review-import.js <path/to/<code>.csv> [--apply]
 *
 * Defaults to dry-run mode (prints changes without writing).
 * Pass `--apply` to write updates to data/translations/<code>.json.
 */

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
const applyFlag = args.includes('--apply');
const csvArg = args.find((a) => !a.startsWith('--'));

if (!csvArg) {
  console.error('Usage: node tools/seed/review-import.js <path/to/<code>.csv> [--apply]');
  process.exit(1);
}

const csvPath = path.resolve(process.cwd(), csvArg);
if (!fs.existsSync(csvPath)) {
  console.error(`Error: CSV file not found: ${csvPath}`);
  process.exit(1);
}

const langCode = path.basename(csvPath, '.csv');
const transPath = path.join(__dirname, 'data', 'translations', `${langCode}.json`);
if (!fs.existsSync(transPath)) {
  console.error(`Error: Target translation JSON not found: ${transPath}`);
  process.exit(1);
}

const EXPECTED_COLUMNS = [
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

/**
 * Strict RFC-4180 CSV parser supporting UTF-8 BOM, quoted fields, escaped quotes, and multiline cells.
 */
function parseCsv(content) {
  const clean = content.startsWith('\uFEFF') ? content.slice(1) : content;
  const rows = [];
  let row = [];
  let cell = '';
  let inQuotes = false;

  for (let i = 0; i < clean.length; i++) {
    const ch = clean[i];

    if (inQuotes) {
      if (ch === '"') {
        if (clean[i + 1] === '"') {
          cell += '"';
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        cell += ch;
      }
    } else {
      if (ch === '"') {
        if (cell.length > 0) {
          throw new Error(`Malformed CSV: unexpected quote inside unquoted field at offset ${i}`);
        }
        inQuotes = true;
      } else if (ch === ',') {
        row.push(cell);
        cell = '';
      } else if (ch === '\r') {
        if (clean[i + 1] === '\n') i++;
        row.push(cell);
        rows.push(row);
        row = [];
        cell = '';
      } else if (ch === '\n') {
        row.push(cell);
        rows.push(row);
        row = [];
        cell = '';
      } else {
        cell += ch;
      }
    }
  }

  if (inQuotes) {
    throw new Error('Malformed CSV: unclosed quoted field at end of file');
  }
  if (cell.length > 0 || row.length > 0) {
    row.push(cell);
    rows.push(row);
  }

  return rows;
}

let rows;
try {
  rows = parseCsv(fs.readFileSync(csvPath, 'utf8'));
} catch (err) {
  console.error(`❌ Failed to parse CSV: ${err.message}`);
  process.exit(1);
}

if (rows.length < 2) {
  console.error('❌ Error: CSV file contains no data rows.');
  process.exit(1);
}

const header = rows[0].map((h) => h.trim());
for (const col of EXPECTED_COLUMNS) {
  if (!header.includes(col)) {
    console.error(`❌ Error: CSV header is missing required column '${col}'.`);
    process.exit(1);
  }
}

const colIdx = Object.fromEntries(header.map((h, i) => [h, i]));
const translations = JSON.parse(fs.readFileSync(transPath, 'utf8'));

const errors = [];
const changes = [];

for (let r = 1; r < rows.length; r++) {
  const row = rows[r];
  const lineNum = r + 1;
  if (row.length === 1 && row[0].trim() === '') continue;

  if (row.length !== header.length) {
    errors.push(`Line ${lineNum}: expected ${header.length} columns but found ${row.length}`);
    continue;
  }

  const slug = (row[colIdx.slug] || '').trim();
  const status = (row[colIdx.status] || '').trim().toLowerCase();
  const corrText = (row[colIdx.correction_text] || '').trim();
  const corrPron = (row[colIdx.correction_pronunciation] || '').trim();
  const corrEx = (row[colIdx.correction_example] || '').trim();

  if (!slug) {
    errors.push(`Line ${lineNum}: missing 'slug'`);
    continue;
  }

  const existing = translations[slug];
  if (!existing) {
    errors.push(`Line ${lineNum}: unknown phrase slug '${slug}' not present in ${langCode}.json`);
    continue;
  }

  if (status === '') {
    // Unreviewed row, leave unchanged
    continue;
  }

  if (status === 'ok') {
    if (existing.verified !== true) {
      changes.push({
        slug,
        action: 'verify',
        summary: `[${slug}] status=ok -> verified: true`,
        apply: () => {
          existing.verified = true;
        },
      });
    }
  } else if (status === 'fix') {
    if (!corrText || (!corrPron && langCode !== 'en') || !corrEx) {
      errors.push(
        `Line ${lineNum} (${slug}): status 'fix' requires non-empty correction_text, ` +
          `${langCode !== 'en' ? 'correction_pronunciation, and ' : ''}correction_example`
      );
      continue;
    }

    changes.push({
      slug,
      action: 'fix',
      summary:
        `[${slug}] status=fix -> text="${corrText}", pronunciation="${corrPron}", ` +
        `exampleSentence="${corrEx}", verified: true`,
      apply: () => {
        existing.text = corrText;
        existing.pronunciation = corrPron;
        existing.exampleSentence = corrEx;
        existing.verified = true;
      },
    });
  } else {
    errors.push(`Line ${lineNum} (${slug}): invalid status '${status}' (must be 'ok', 'fix', or empty)`);
  }
}

if (errors.length > 0) {
  console.error(`\n❌ Review import rejected with ${errors.length} error(s):`);
  errors.forEach((e, i) => console.error(`  ${i + 1}. ${e}`));
  process.exit(1);
}

console.log(`--- Review Import (${applyFlag ? 'APPLY MODE' : 'DRY-RUN MODE'}) for '${langCode}' ---`);
if (changes.length === 0) {
  console.log('No changes to apply.');
  process.exit(0);
}

for (const change of changes) {
  console.log(`  • ${change.summary}`);
}

if (applyFlag) {
  for (const change of changes) {
    change.apply();
  }
  fs.writeFileSync(transPath, JSON.stringify(translations, null, 2) + '\n', 'utf8');
  console.log(`\n✅ Applied ${changes.length} change(s) to ${path.relative(process.cwd(), transPath)}`);
} else {
  console.log(`\nℹ️  Dry run complete: ${changes.length} change(s) would be applied. Re-run with --apply to write changes.`);
}
