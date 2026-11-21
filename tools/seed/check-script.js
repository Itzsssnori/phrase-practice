#!/usr/bin/env node

/**
 * Per-language translation script & quality checker for Phrase Practice.
 *
 * Usage:
 *   node tools/seed/check-script.js <code>
 *
 * Validates data/translations/<code>.json against data/phrases.json and data/translations/en.json:
 * 1. Missing phrase or empty required field (text, pronunciation, exampleSentence; meaningNote optional).
 * 2. text identical to English text, or any field containing placeholders (TODO, ???, ..., lorem).
 * 3. Script rules for the target language (expected script present, forbidden scripts absent).
 * 4. pronunciation characters (Latin letters, language-specific allowed diacritics, spaces,
 *    apostrophes, hyphens, basic punctuation; no digits).
 * 5. text or exampleSentence length > 200 characters.
 */

const fs = require('fs');
const path = require('path');

const code = process.argv[2];
if (!code) {
  console.error('Usage: node tools/seed/check-script.js <code>');
  process.exit(1);
}

const dataDir = path.join(__dirname, 'data');
const phrasesFile = path.join(dataDir, 'phrases.json');
const enFile = path.join(dataDir, 'translations', 'en.json');
const targetFile = path.join(dataDir, 'translations', `${code}.json`);

if (!fs.existsSync(phrasesFile) || !fs.existsSync(enFile)) {
  console.error('Error: phrases.json or translations/en.json not found.');
  process.exit(1);
}
if (!fs.existsSync(targetFile)) {
  console.error(`Error: translation file data/translations/${code}.json does not exist.`);
  process.exit(1);
}

const phrases = JSON.parse(fs.readFileSync(phrasesFile, 'utf8'));
const enMap = JSON.parse(fs.readFileSync(enFile, 'utf8'));
const targetMap = JSON.parse(fs.readFileSync(targetFile, 'utf8'));

const PLACEHOLDER_REGEX = /(\bTODO\b|\?\?\?|\.\.\.|\blorem\b)/i;

// Traditional-only character set for zh (Simplified Mandarin check)
const TRADITIONAL_ONLY_CHARS = new Set(
  '這個們麼嗎學說沒與會來對時點開關買錢裡邊還進過問聽讓給請謝號機場車驛鐵館飯飲醫藥護證銀幣價費碼電話網絡腦體國際處務員師親屬兒歲氣陰陽風雲颱險警報竊盜賊失尋找據單簽訂房間層樓梯廁紙巾浴室票導遊覽應當後發見長門東兩無萬現經頭動體實種聲話愛給難題選寫認識條線變讓'.split(
    ''
  )
);

const ALLOWED_LATIN_LOANWORDS = /\b(Wi-Fi|QR|ATM|SIM|GPS|USB|SMS|ID|PIN|VIP|COVID|LRT|MRT|CR|PWD)\b/gi;

function checkScriptForLanguage(lang, text) {
  const issues = [];
  const hasLatin = /[A-Za-z\u00C0-\u024F]/.test(text);
  const hasCyrillic = /[\u0400-\u04FF]/.test(text);
  const hasGreek = /[\u0370-\u03FF]/.test(text);
  const hasHan = /[\u4E00-\u9FFF]/.test(text);
  const hasKana = /[\u3040-\u30FF]/.test(text);
  const hasHangul = /[\uAC00-\uD7AF\u1100-\u11FF\u3130-\u318F]/.test(text);

  if (lang === 'fr' || lang === 'es' || lang === 'fil' || lang === 'en') {
    if (!hasLatin) issues.push('lacks Latin characters');
    if (hasCyrillic) issues.push('contains Cyrillic characters');
    if (hasGreek) issues.push('contains Greek characters');
    if (hasHan || hasKana || hasHangul) issues.push('contains CJK/kana/Hangul characters');
  } else if (lang === 'ru') {
    if (!hasCyrillic) issues.push('lacks Cyrillic characters');
    if (hasHan || hasKana || hasHangul) issues.push('contains Han/kana/Hangul characters');
    const stripped = text.replace(ALLOWED_LATIN_LOANWORDS, '');
    if (/[A-Za-z]/.test(stripped)) {
      issues.push('contains unexpected Latin characters outside allowed loan terms (e.g. Wi-Fi)');
    }
  } else if (lang === 'ko') {
    if (!hasHangul) issues.push('lacks Hangul characters');
    if (hasHan) issues.push('contains Han characters');
    if (hasKana) issues.push('contains Japanese kana');
    if (hasCyrillic) issues.push('contains Cyrillic characters');
  } else if (lang === 'ja') {
    if (!hasHan && !hasKana) issues.push('lacks Japanese characters (kanji/hiragana/katakana)');
    if (hasHangul) issues.push('contains Hangul characters');
    if (hasCyrillic) issues.push('contains Cyrillic characters');
    const stripped = text.replace(ALLOWED_LATIN_LOANWORDS, '');
    if (/[A-Za-z]/.test(stripped)) {
      issues.push('contains unexpected Latin/romaji characters outside allowed loan terms (e.g. Wi-Fi)');
    }
  } else if (lang === 'zh') {
    if (!hasHan) issues.push('lacks Han characters');
    if (hasKana) issues.push('contains Japanese kana');
    if (hasHangul) issues.push('contains Hangul characters');
    if (hasCyrillic) issues.push('contains Cyrillic characters');
    const tradFound = [];
    for (const ch of text) {
      if (TRADITIONAL_ONLY_CHARS.has(ch) && !tradFound.includes(ch)) {
        tradFound.push(ch);
      }
    }
    if (tradFound.length > 0) {
      issues.push(`contains Traditional-only characters: ${tradFound.join(' ')}`);
    }
  }
  return issues;
}

function checkPronunciationForLanguage(lang, pron) {
  const issues = [];
  if (/\d/.test(pron)) {
    issues.push('contains digits');
  }
  let allowedRegex;
  if (lang === 'ja') {
    allowedRegex = /^[A-Za-zāēīōūĀĒĪŌŪ\s'.,/?!;:-]+$/;
  } else if (lang === 'zh') {
    allowedRegex = /^[A-Za-zāáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜĀÁǍÀĒÉĚÈĪÍǏÌŌÓǑÒŪÚǓÙǕǗǙǛ\s'.,/?!;:-]+$/;
  } else if (lang === 'ko') {
    // Revised Romanization: no hyphens, no diacritics
    if (/-/.test(pron)) {
      issues.push('contains hyphen (disallowed in Revised Romanization for ko)');
    }
    allowedRegex = /^[A-Za-z\s'.,/?!;:]+$/;
  } else {
    // fr, ru, es, fil: ASCII Latin letters + basic punctuation/hyphens/spaces/apostrophes
    allowedRegex = /^[A-Za-z\s'.,/?!;:-]+$/;
  }

  if (!allowedRegex.test(pron)) {
    issues.push(`contains invalid characters for ${lang} pronunciation`);
  }
  return issues;
}

const ruleCounts = {
  missingOrEmpty: 0,
  identicalOrPlaceholder: 0,
  scriptError: 0,
  pronunciationError: 0,
  lengthError: 0,
};

const errors = [];

for (const phrase of phrases) {
  const slug = phrase.slug;
  const entry = targetMap[slug];
  if (!entry) {
    ruleCounts.missingOrEmpty++;
    errors.push(`[${slug}] (entry): missing phrase in data/translations/${code}.json`);
    continue;
  }

  // Rule 1: Required fields non-empty (meaningNote may be empty string)
  for (const reqField of ['text', 'pronunciation', 'exampleSentence']) {
    if (typeof entry[reqField] !== 'string' || entry[reqField].trim().length === 0) {
      if (code === 'en' && reqField === 'pronunciation' && typeof entry[reqField] === 'string') {
        continue;
      }
      ruleCounts.missingOrEmpty++;
      errors.push(`[${slug}] (${reqField}): missing or empty required field`);
    }
  }
  if (typeof entry.meaningNote !== 'string') {
    ruleCounts.missingOrEmpty++;
    errors.push(`[${slug}] (meaningNote): must be a string (use "" when empty)`);
  }
  if (entry.verified !== false) {
    ruleCounts.missingOrEmpty++;
    errors.push(`[${slug}] (verified): expected false, got ${JSON.stringify(entry.verified)}`);
  }

  const text = typeof entry.text === 'string' ? entry.text.trim() : '';
  const pron = typeof entry.pronunciation === 'string' ? entry.pronunciation.trim() : '';
  const example = typeof entry.exampleSentence === 'string' ? entry.exampleSentence.trim() : '';
  const note = typeof entry.meaningNote === 'string' ? entry.meaningNote.trim() : '';

  // Rule 2: Identical to English or contains placeholders
  if (code !== 'en' && enMap[slug] && text.toLowerCase() === enMap[slug].text.trim().toLowerCase()) {
    ruleCounts.identicalOrPlaceholder++;
    errors.push(`[${slug}] (text): identical to English text "${enMap[slug].text}"`);
  }
  for (const [fName, fVal] of [
    ['text', text],
    ['pronunciation', pron],
    ['exampleSentence', example],
    ['meaningNote', note],
  ]) {
    if (PLACEHOLDER_REGEX.test(fVal)) {
      ruleCounts.identicalOrPlaceholder++;
      errors.push(`[${slug}] (${fName}): contains placeholder string (TODO, ???, ..., lorem)`);
    }
  }

  // Rule 3: Script validation
  if (text.length > 0) {
    const scriptIssues = checkScriptForLanguage(code, text);
    for (const issue of scriptIssues) {
      ruleCounts.scriptError++;
      errors.push(`[${slug}] (text): ${issue}`);
    }
  }
  if (example.length > 0) {
    const exScriptIssues = checkScriptForLanguage(code, example);
    for (const issue of exScriptIssues) {
      ruleCounts.scriptError++;
      errors.push(`[${slug}] (exampleSentence): ${issue}`);
    }
  }

  // Rule 4: Pronunciation validation
  if (pron.length > 0) {
    const pronIssues = checkPronunciationForLanguage(code, pron);
    for (const issue of pronIssues) {
      ruleCounts.pronunciationError++;
      errors.push(`[${slug}] (pronunciation): ${issue} ("${pron}")`);
    }
  }

  // Rule 5: Length limit (<= 200 characters)
  if (text.length > 200) {
    ruleCounts.lengthError++;
    errors.push(`[${slug}] (text): exceeds 200 characters (${text.length} chars)`);
  }
  if (example.length > 200) {
    ruleCounts.lengthError++;
    errors.push(`[${slug}] (exampleSentence): exceeds 200 characters (${example.length} chars)`);
  }
}

console.log(`--- Script & Quality Check for '${code}' (${phrases.length} phrases) ---`);
console.log(`  1. Missing phrases / empty required fields : ${ruleCounts.missingOrEmpty}`);
console.log(`  2. Identical to English / placeholders     : ${ruleCounts.identicalOrPlaceholder}`);
console.log(`  3. Script violations                       : ${ruleCounts.scriptError}`);
console.log(`  4. Pronunciation format violations         : ${ruleCounts.pronunciationError}`);
console.log(`  5. Length (> 200 chars) violations         : ${ruleCounts.lengthError}`);

if (errors.length > 0) {
  console.error(`\n❌ CHECK-SCRIPT FAILED for '${code}' with ${errors.length} error(s):`);
  errors.forEach((e, i) => console.error(`  ${i + 1}. ${e}`));
  process.exit(1);
} else {
  console.log(`\n✅ CHECK-SCRIPT PASSED: All ${phrases.length} '${code}' entries passed every check!`);
}
